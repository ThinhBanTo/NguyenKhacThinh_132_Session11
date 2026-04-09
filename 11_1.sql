--tao table
create table flights(
    flight_id serial primary key ,
    flight_name varchar(100),
    available_seats int
);

create table bookings(
    booking_id serial primary key ,
    flight_id int references flights(flight_id),
    customer_name varchar(100)
);
--insert du lieu vao
insert into flights(flight_name, available_seats)
values ('VN123',3),('VN456',2);

--1
create or replace procedure booking_by_name(
    name_in varchar,
    flight_id_in int
) language plpgsql as $$
    declare
    begin
        if not exists(select 1 from flights where flight_id=flight_id_in) then
            raise exception 'Chuyen bay id % nay khong ton tai, vui long doi chuyen bay khac',flight_id_in;
        end if;

        if (select flights.available_seats from flights where flight_id=flight_id_in) =0 then
            raise exception 'Chuyen bay co id % nay da het cho, vui long doi chuyen bay khac',flight_id_in;
        end if;

        insert into bookings(flight_id, customer_name)
        values (flight_id_in,name_in);

        update flights
        set available_seats=available_seats-1
        where flight_id=flight_id_in;

        --bao dat hang thanh cong
        raise notice 'Dat ve thanh cong';

    exception
        when others then
        raise;
    end;
    $$;
--2
select * from flights;
--flight_id sai
call booking_by_name('Nguyen Van A',3);




