--tao table
create table products(
    product_id serial primary key ,
    product_name varchar(100),
    stock int,
    price numeric
);

create table orders(
    order_id serial primary key ,
    customer_name varchar(100),
    total_amount numeric(10,2),
    created_at timestamp default now()
);

create table order_items(
    order_item_id serial primary key ,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int,
    subtotal numeric(10,2)
);
--tao procedure->transaction
create or replace procedure order_product(
    name_in varchar,
    pro_id_1 int,
    pro_quantity_1 int,
    pro_id_2 int,
    pro_quantity_2 int
)
language plpgsql as
$$
    declare
        pro_price_1 numeric;
        pro_price_2 numeric;
        order_id_1 int;
    begin
        --b: roll back neu 1 trong 2 san pham khong du hang
        if (select products.stock from products where product_id=pro_id_1) < pro_quantity_1
            or (select products.stock from products where product_id=pro_id_2) < pro_quantity_2
            then raise exception 'Có sản phẩm không đủ số lượng tồn kho';
        end if;
        --giam so luong ton kho
        update products
        set stock=stock-pro_quantity_1
        where product_id=pro_id_1;

        update products
        set stock=stock-pro_quantity_2
        where product_id=pro_id_2;
        --tao ban ghi trong order
        insert into orders(customer_name)
        values (name_in)
        returning order_id into order_id_1;  --dua order_id moi vao 1 bien
        --insert order_items
        --luu gia 2 sp va order_id

        select price into pro_price_1
        from products
        where product_id=pro_id_1;

        select price into pro_price_2
        from products
        where product_id=pro_id_2;

        insert into order_items(order_id, product_id, quantity, subtotal)
        values(order_id_1,pro_id_1,pro_quantity_1,pro_price_1*pro_quantity_1),
              (order_id_1,pro_id_2,pro_quantity_2,pro_price_2*pro_quantity_2);
        --update lai total_amount
        update orders
        set total_amount=(select sum(subtotal) from order_items where order_items.order_id=order_id_1)
        where order_id=order_id_1;

    exception
        when others then
        raise;
    end;
    $$;
--2:
UPDATE products SET stock = 100 WHERE product_id = 1;
UPDATE products SET stock = 0 WHERE product_id = 2; -- Sản phẩm này hết hàng

CALL order_product('Nguyen Van A', 1, 2, 2, 1);



