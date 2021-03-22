--洗数据测试
select thisdate, count(1)
from rpt.base_nequal_bid_uid
where thisdate >= '2020-12-02'
group by 1

--推 OTT包
presto --execute "
-- 0 代表所有广告主
select user_id, 4, mac, geo_code, 0, ua_id
from rpt.base_device_ua_id_v2
--thisdate写前天日期（一般情况）
where thisdate = '2021-03-07'
  and ua_id not in ('0', '-1')
  and uid_type = '4' -- OTT
  --去dim_area里查地名(geo_b_code)
  and geo_code in ('156024000011','156024000013')
group by 1, 2, 3, 4, 5, 6 limit 20000000
" --output-format TSV > 1739__202101061316;"


-- 一价成交
select thisdate,
       ext_slot_id,
       count(distinct ext_request_id)                                                as imp,
       sum(cost_price * 1.000000000 / 1000000000)                                    as cost,
       count(distinct if(ext_bid_price = cost_price, ext_request_id, null))          as yijia_imp,
       sum(if(ext_bid_price = cost_price, cost_price * 1.000000000 / 1000000000, 0)) as yijia_cost
from dwd.d_ad_ftx_win_data
where thisdate >= '2020-11-01'
  and thisdate <= '2020-11-10'
  and ext_vendor_id = 120
group by 1, 2


--TA包 有条件
select distinct a.ext_user_id,
                case
                    when a.ext_device_type = 4 then 4
                    else pf end         jixing,
                case
                    when a.ext_device_type = 4 then a.ext_mobile_mac
                    else '528C8E6CD4A3C6598999A0E9DF15AD32'
                    end                 mac,
                case
                    when d.geo_id is null then cast(a.geoid as varchar)
                    else d.geo_b_id end geoid,
                a.ext_advertiser_id,
                a.ua_id_v2
from (
         select ext_user_id
              , case
                    when ext_platform = 'Android' and length(ext_user_id) = 32 then 1
                    when ext_platform = 'IOS' then 2
                    else 3 end  pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id) geoid
         from dwd.d_ad_impression
         where ext_order_id = 2464
           and ext_advertiser_id = 2003513
           and thisdate >= '2020-08-06'
           and thisdate <= '2020-10-15'
         group by 1, 2, 3, 4, 5, 6
     ) a
         left join
     (
         select distinct ext_user_id
         from dwd.d_ad_impression
         where ext_order_id = 2805
           and ext_advertiser_id = 2003584
           and thisdate >= '2020-11-13'
           and thisdate <= '2020-12-31'
     ) b
     on a.ext_user_id = b.ext_user_id
         join
     u6rds.ad_fancy.base_ua_id_info c
     on cast(a.ua_id_v2 as varchar) = c.ua_id
         left join
     (
         select geo_id, geo_b_id
         from dim.dim_area
     ) d
     on a.geoid = d.geo_id
where b.ext_user_id is null

-- 推洗过的数据可能会超内存 限制2亿在中间
with
tag_sub as (
    select uid
    from rpt.base_nequal_uid_tags
    where thisdate = '2020-12-16'
    and (mz_gender in ('2500100020')
    or qtt_gender in ('2500100020')
    or wb_gender  in ('2500100020') )
)

    ,
user_sub as (
    select user_id as uid,
      uid_type,
      geo_code,
      mac,
      2003558 as advertiser_id,
      ua_id
    from rpt.base_device_ua_id_v2
    where  thisdate = '2021-01-05' and ua_id not in ('0','-1') and uid_type in ('1','2','3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
)

    ,
    ua_sub as (
        select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid as user_id
    , user_sub.uid_type
    , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
    , user_sub.geo_code
    , user_sub.advertiser_id
    , user_sub.ua_id
from  tag_sub join user_sub on tag_sub.uid = user_sub.uid
limit 20000000
" --output-format TSV > 1746__202101071131;";



-- 手推TA包
presto --execute "
select distinct a.ext_user_id,
                pf,
                '528C8E6CD4A3C6598999A0E9DF15AD32',
                case
                    when d.geo_id is null then cast(a.geoid as varchar)
                    else d.geo_b_id end geoid,
                a.ext_advertiser_id,
                a.ua_id_v2
from (
         select ext_user_id
              , case
                    when ext_platform = 'Android' and length(ext_user_id) = 32 then 1
                    when ext_platform = 'IOS' then 2
                    else 3 end                 pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id)                geoid
              , count(distinct ext_request_id) pc
         from dwd.d_ad_impression
         where ext_adgroup_id in
               (250961, 250964, 250967, 250970, 250973, 250976, 250977, 250978, 250979, 250995, 250996, 250997, 250998,
                250999, 251000, 250938, 250939, 250940, 250960, 250963, 250966, 250969, 250972, 250975, 251033, 251034,
                251035)
           and thisdate >= '2021-03-04'
         group by 1, 2, 3, 4, 5, 6
     ) a
         join
     u6rds.ad_fancy.base_ua_id_info c
     on cast(a.ua_id_v2 as varchar) = c.ua_id
         left join
     (
         select geo_id, geo_b_id
         from dim.dim_area
     ) d
     on a.geoid = d.geo_id
where a.pc >= 2
    " --output-format TSV > 1840__202103031531;"


