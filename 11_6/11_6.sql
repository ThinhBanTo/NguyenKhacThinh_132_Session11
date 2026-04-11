create table accounts(
    account_id serial primary key ,
    owner_name varchar(100),
    balance numeric(12,2),
    status varchar(10) default 'ACTIVE'
);

create table transactions(
    trans_id serial primary key ,
    from_account int references accounts(account_id),
    to_account int references accounts(account_id),
    amount numeric(12,2),
    status varchar(20) default 'PENDING',
    created_at timestamp default now()
);

create or replace procedure safe_transaction(
    p_id_nguoi_gui int,
    p_id_nguoi_nhan int,
    p_amount numeric
)language plpgsql
as $$
    declare
        v_status varchar;
        v_balance numeric;
    begin
        --khoa ca 2 tai khoan theo thu tu id de tranh deadlock
            perform balance from accounts where account_id=p_id_nguoi_gui for update ;
            perform balance from accounts where account_id=p_id_nguoi_nhan for update ;

        perform pg_sleep(60);

            select status,balance into v_status,v_balance
            from accounts
            where account_id=p_id_nguoi_gui;

            if v_status!='ACTIVE' or v_balance<p_amount then
                raise exception 'Chuyen khoan khong thanh cong';
            end if;

            update accounts
            set balance=balance-p_amount
            where account_id=p_id_nguoi_gui;

            update accounts
            set balance=balance+p_amount
            where account_id=p_id_nguoi_nhan;


            insert into transactions(from_account, to_account, amount, status)
            values (p_id_nguoi_gui,p_id_nguoi_nhan,p_amount,'COMPLETE');

            raise notice 'Transaction completed!';
    end;
    $$;

create or replace procedure test (
    p_id int,
    p_amount numeric
)language plpgsql as
$$
    begin
        perform pg_sleep(5);
        update accounts
        set balance=balance-p_amount
        where account_id=p_id;
    end;
    $$;

--chay 2 procedure
select * from accounts;
call safe_transaction(1,2,100000);




