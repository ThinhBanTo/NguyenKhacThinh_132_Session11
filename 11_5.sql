--tao table
create table customers(
    customer_id serial primary key ,
    name varchar(100),
    balance numeric(12,2)
);

create table products(
    product_id serial primary key ,
    name varchar(100),
    stock int,
    price numeric(10,2)
);

create table orders(
    order_id serial primary key ,
    customer_id int references customers(customer_id),
    total_amount numeric(12,2),
    created_at timestamp default now(),
    status varchar(20) default 'PENDING'
);

create table order_items(
    item_id serial primary key ,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int,
    subtotal numeric(10,2)
);
--tao transaction trong procedure
create or replace procedure new_order(
) language plpgsql as
$$
    declare
        v_customer_id int;
        v_balance numeric(12,2);

        v_price_1 numeric;
        v_price_2 numeric;
        v_stock_1 int;
        v_stock_2 int;
        v_total_amount numeric;
        v_new_order_id int;
    begin
        select balance,customer_id into v_balance,v_customer_id
        from customers
        where name='Tran Thi B';

        select price,stock into v_price_1,v_stock_1
        from products
        where product_id=1;

        select price,stock into v_price_2,v_stock_2
        from products
        where product_id=3;

        if v_stock_1<1 or v_stock_2<2 then
            raise exception E'Co san pham khong du hang ton kho!\nSan pham id 1 con %\nSan pham id 3 con %',v_stock_1,v_stock_2;
        end if;

        v_total_amount:=v_price_1+2*v_price_2;
        if v_balance<v_total_amount then
            raise exception E'Tai khoan quy khach khong du tien mua hang!\nSo tien con lai la %',v_balance;
        end if;

        insert into orders(customer_id, total_amount, status)
        values (v_customer_id,v_total_amount,'COMPLETED')
        returning order_id into v_new_order_id;

        insert into order_items(order_id, product_id, quantity, subtotal)
        values (v_new_order_id,1,1,v_price_1),
               (v_new_order_id,3,2,2*v_price_2);

        update customers
        set balance=balance-v_total_amount
        where customer_id=v_customer_id;

        update products
        set stock=stock-1
        where product_id=1;

        update products
        set stock=stock-2
        where product_id=3;

        raise notice 'Tao don hang thanh cong';
    end;
    $$;

