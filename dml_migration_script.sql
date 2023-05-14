insert into public.shipping_country_rates(shipping_country, shipping_country_base_rate)
select distinct shipping_country, shipping_country_base_rate  
from shipping; 



insert into public.shipping_agreement
select distinct (regexp_split_to_array(vendor_agreement_description, ':+'))[1]::bigint as agreement_id,
	   (regexp_split_to_array(vendor_agreement_description, ':+'))[2] as agreement_number,
	   (regexp_split_to_array(vendor_agreement_description, ':+'))[3]:: numeric(14,2) as agreement_rate,
	   (regexp_split_to_array(vendor_agreement_description, ':+'))[4]:: numeric(14,2) as agreement_commission
from shipping s 



insert into public.shipping_transfer(transfer_type, transfer_model, shipping_transfer_rate)
select distinct (regexp_split_to_array(shipping_transfer_description, ':+'))[1] as transfer_type, 
	   (regexp_split_to_array(shipping_transfer_description, ':+'))[2] as transfer_model,
		shipping_transfer_rate  
from shipping


insert into public.shipping_info
select distinct shippingid, 
	   scr.shipping_country_id, 
	   (regexp_split_to_array(vendor_agreement_description, ':+'))[1]::bigint as agreement_id, 
	   st.transfer_type_id, 
	   shipping_plan_datetime, 
	   payment_amount, 
	   vendorid 
from shipping s
left join shipping_country_rates scr on scr.shipping_country = s.shipping_country and scr.shipping_country_base_rate = s.shipping_country_base_rate  
left join shipping_transfer st on st.transfer_type = (regexp_split_to_array(s.shipping_transfer_description, ':+'))[1] and st.transfer_model = (regexp_split_to_array(s.shipping_transfer_description, ':+'))[2] and st.shipping_transfer_rate  = s.shipping_transfer_rate  


insert into shipping_status
with shipping_max_date as (
	select shippingid, 
		   max(state_datetime) as state_datetime
	from shipping s
	group by shippingid
), booked_and_recieved as (
	select shippingid, 
		   max(case when state = 'booked' then state_datetime
		   end) as shipping_start_fact_datetime,
		   max(case when state = 'recieved' then state_datetime
		   end) as shipping_end_fact_datetime
	from shipping
	where state = 'booked' or state = 'recieved'
	group by shippingid
)
select s.shippingid, s.status, s.state, shipping_start_fact_datetime, shipping_end_fact_datetime  
from shipping_max_date smd
left join shipping  s on smd.shippingid = s.shippingid and smd.state_datetime = s.state_datetime 
left join booked_and_recieved bar on smd.shippingid = bar.shippingid
order by smd.shippingid asc
