CREATE TABLE tpcds.inventory (
    inv_date_sk integer NOT NULL,
    inv_item_sk integer NOT NULL,
    inv_warehouse_sk integer NOT NULL,
    inv_quantity_on_hand integer
)
WITH (:LARGE_STORAGE)
:DISTRIBUTED_BY
PARTITION BY RANGE (inv_date_sk)
(
PARTITION part_1998_01 START (2450815) END (2451180),
PARTITION part_1999_01 START (2451180) END (2451545),
PARTITION part_2000_01 START (2451545) END (2451911),
PARTITION part_2001_01 START (2451911) END (2452276),
PARTITION part_2002_01 START (2452276) END (2452641),
PARTITION part_2003_01 START (2452641) END (2452672),
DEFAULT PARTITION no_date_set
);
/*
partition by range(inv_date_sk)
(start(2450815) INCLUSIVE end(2453005) INCLUSIVE every (28),
default partition others);
*/
