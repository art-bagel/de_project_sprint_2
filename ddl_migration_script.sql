drop table if exists public.shipping_country_rates cascade;
create table public.shipping_country_rates (
	shipping_country_id serial primary key,
	shipping_country varchar(30),
	shipping_country_base_rate numeric(14,2)
)



drop table if exists public.shipping_agreement cascade;
create table public.shipping_agreement(
	agreementid bigint primary key,
	agreement_number varchar(50),
	agreement_rate numeric(14,2),
	agreement_commission numeric(14,2)
)


drop table if exists public.shipping_transfer cascade;
create table public.shipping_transfer(
    transfer_type_id serial primary key,
	transfer_type varchar(5),
	transfer_model varchar(20),
	shipping_transfer_rate numeric(14,4)
)


drop table if exists public.shipping_info;
create table public.shipping_info(
	shippingid bigint primary key,
	shipping_country_rates_id bigint,
	shipping_agreement_id bigint,
	shipping_transfer_id bigint,
	shipping_plan_datetime timestamp,
	payment_amount numeric(14,2),
	vendorid bigint,
	FOREIGN KEY (shipping_country_rates_id) REFERENCES shipping_country_rates (shipping_country_id) on update cascade on delete set null,
	FOREIGN KEY (shipping_agreement_id) REFERENCES shipping_agreement (agreementid) on update cascade on delete set null,
	FOREIGN KEY (shipping_transfer_id) REFERENCES shipping_transfer (transfer_type_id) on update cascade on delete set null
)

drop table if exists public.shipping_status;
create table public.shipping_status(
	shippingid bigint,
	status varchar(30),
	state varchar(20),
	shipping_start_fact_datetime timestamp,
	shipping_end_fact_datetime timestamp
)




create or replace view shipping_datamart as (
    with new_shipping_status as (
        select shippingid, 
        	   status, 
        	   state, 
        	   shipping_start_fact_datetime, 
        	   case 
	        	   when shipping_end_fact_datetime is null then now()::timestamp 
	        	   else shipping_end_fact_datetime 
	           end 
	    from shipping_status
    )
	select si.shippingid, --
		   si.vendorid, --
		   st.transfer_type, --
		   date_part('day', shipping_end_fact_datetime - shipping_start_fact_datetime) as full_day_at_shipping,
		   case 
			   when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then 1 
			   else 0 
		   end as is_delay,
		   case 
			   when ss.status = 'finished' then 1
			   else 0
		   end as is_shipping_finish,
		   case 
		   	   when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then date_part('day', ss.shipping_end_fact_datetime - si.shipping_plan_datetime)
		   	   else 0
		   end as delay_day_at_shipping,
		   si.payment_amount,
		   si.payment_amount * (scr.shipping_country_base_rate + sa.agreement_rate + st.shipping_transfer_rate) as vat,
		   si.payment_amount * sa.agreement_commission as profit
	from shipping_info si
	left join shipping_transfer st on st.transfer_type_id = si.shipping_transfer_id 
	left join new_shipping_status ss on ss.shippingid = si.shippingid 
	left join shipping_agreement sa  on sa.agreementid = si.shipping_agreement_id
	left join shipping_country_rates scr on scr.shipping_country_id = si.shipping_country_rates_id 
)



