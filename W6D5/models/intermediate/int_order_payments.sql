
select
    o.order_id,
    o.customer_id,
    o.product_id,
    o.order_date,
    o.quantity,
    o.unit_price,
    o.order_status,

    o.quantity * o.unit_price as order_amount,

    case
        when lower(o.order_status) = 'refunded' then 0
        else o.quantity * o.unit_price
    end as net_amount

from {{ ref('stg_orders') }} o
