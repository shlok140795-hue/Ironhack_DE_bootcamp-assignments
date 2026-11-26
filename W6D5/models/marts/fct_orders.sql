
select
    p.order_id,
    p.customer_id,
    c.customer_name,
    c.email,
    c.city,
    p.product_id,
    p.order_date,
    p.quantity,
    p.unit_price,
    p.order_amount,
    p.order_status,
    p.net_amount

from {{ ref('int_order_payments') }} p

left join {{ ref('stg_customers') }} c
    on p.customer_id = c.customer_id
