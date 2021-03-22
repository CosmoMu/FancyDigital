-- 期望成本和CPM
select dat,
       name,
       cost                                                                      as
           "成本",
       if(cost is null or expect = 0, 0, cost / expect)                          as
           "期望成本比",
       if(imp is null or imp = 0, 0, cost / imp * 1000)                          as
           "CPM",
       if(last_cost is null or last_cost = 0, 0, (cost - last_cost) / last_cost) as
           "成本日环比",
       if(imp is null or imp = 0 or last_cost is null or last_cost = 0 or last_imp is null or last_imp = 0, 0,
          ((cost / imp) - (last_cost / last_imp)) / (last_cost / last_imp))      as
           "CPM日环比"
from (
         select dat,
                name,
                cost,
                imp,
                expect,
                lag(cost) over (partition by name order by dat) as last_cost,
                lag(imp)  over (partition by name order by dat)  as last_imp
         from (
                  select detail.dat,
                         od.name,
                         sum(total_price / (date_diff('day', start_date, end_date) + 1)) as expect,
                         sum(detail.cost)                                                as cost,
                         sum(detail.imp)                                                 as imp
                  from (
                           select od.order_id,
                                  od.order_name,
                                  ln.name,
                                  od.total_budget,
                                  start_date,
                                  end_date,
                                  total_price
                           from u6rds.amo."order" od
                                    left join u6rds.amo.alias_name ln
                                              on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
                           where order_system in (1, 2)
                             and od.status
                               > 1
                             and od.status
                               < 7
                             and order_id <> 588
                             and business_line in (1, 2, 3)
                             and end_date >= current_date - interval '1' day
                       ) od
                           left join
                       (
                           select dat
                                , bu
                                , a1.order_id
                                , sum(cost) as cost
                                , sum(imp)  as imp
                           from (
                                    select dat
                                         , case
                                               when bu = 'DSP_RTB' then 'DSP'
                                               when bu in ('FTX_PDB', 'DSP_PDB') then 'GD_Fancy'
                                               when bu = 'FTX_RTB' then 'FTX'
                                               else 'qt'
                                        end                        as bu
                                         , order_id
                                         , sum(reward) + sum(cost) as cost
                                         , sum(imp)                as imp
                                    from (
                                             select dat
                                                  , case
                                                        when d_buid = 2 and vendor_settle = 1 then 'FTX_PDB'
                                                        when d_buid = 2 then 'FTX_RTB'
                                                        when d_buid = 1 and c4.order_system = 4 and c4.order_name like '%（GD_PDB）'
                                                            then 'DSP_PDB'
                                                        when d_buid = 1 and c4.order_system = 4 then 'DSP_GD'
                                                        when d_buid = 1 then 'DSP_RTB'
                                                        else 'qt'
                                                 end                                                      as bu
                                                  , case
                                                        when c4.order_id is not null and c4.order_id <> 0
                                                            then c4.order_id
                                                        when c3.amo_order_id is not null then c3.amo_order_id
                                                        else c1.dsp_id
                                                 end                                                      as order_id
                                                  , sum(if((buid <> s_buid) or (op in (8, 10)), 0, cost)) as cost
                                                  , sum(if(buid = 2 and op in (10), cost, 0))             as reward
                                                  , sum(if(buid = d_buid or op in (6, 7, 10), imp, 0))    as imp
                                             from (
                                                      select dat
                                                           , op
                                                           , buid
                                                           , s_buid
                                                           , d_buid
                                                           , dsp_id
                                                           , d_order_id   as order_id
                                                           , sum(cost)    as cost
                                                           , sum(income)  as income
                                                           , sum(cnt_imp) as imp
                                                      from u6rds.finance.finance_flow_data
                                                      where type != 2
                                                        and dsp_id not in (77)
                                                        and d_buid in (1, 2, 3)
                                                      group by 1, 2, 3, 4, 5, 6, 7
                                                  ) c1
                                                      left join
                                                  (
                                                      select id
                                                           , vendor_settle
                                                      from u6rds.ftx."order"
                                                  ) c2 on c2.id = c1.order_id and c1.d_buid = 2
                                                      left join
                                                  (
                                                      select d1.amo_order_id
                                                           , d1.order_id
                                                           , d2.advertiser_id
                                                           , d2.start_date
                                                           , d2.end_date
                                                           , d2.public_rebate
                                                           , d2.total_budget
                                                           , d2.actual_amount
                                                      from u6rds.ftx.order_detail_amo_order d1
                                                               join u6rds.amo."order" d2
                                                                    on d1.amo_order_id = d2.order_id
                                                  ) c3
                                                  on c3.order_id = c1.order_id and c1.dat >= c3.start_date and
                                                     c1.dat <= c3.end_date and
                                                     c1.d_buid = 2
                                                      left join u6rds.amo."order" c4
                                                                on c1.order_id = c4.order_id and c1.d_buid = 1
                                                      left join u6rds.ftx.dsp c5 on c1.dsp_id = c5.id and c1.d_buid = 2
                                             group by 1, 2, 3
                                         ) b1
                                    group by 1, 2, 3
                                ) a1
                                    left join u6rds.rpt_fancy.base_finance_actual_amount a2 on a1.order_id = a2.order_id
                           where bu <> 'qt'
                           group by 1, 2, 3
                       ) detail on detail.order_id = od.order_id
                  group by 1, 2
              ) t1
     ) t2
where dat = current_date - interval '1' day
order by 3;

-- TA浓度
select order_id,
       order_name,
       people_type,
       concat(cast(round(cast(ta_imp as double) / t_tol * 100, 2) as varchar), '%') ta_p
from (
         select t.order_id order_id, order_name, people_type, imp, ta_imp, sum(imp) over (partition by t.order_id) t_tol
         from (
                  select a.cusid,
                         people_type,
                         a.imp,
                         a.ta_imp,
                         mnt.order_id
                  from (
                           select cusid,
                                  people_type,
                                  sum(case when people_type = '稳定人群' then imp else 0 end)  as imp,
                                  sum(case when people_type <> '稳定人群' then imp else 0 end) as ta_imp
                           from u6rds.rpt_fancy.rpt_mz_reach_accumulate
                           where end_dt = '2020-10-09'
--                         cast((current_date - interval '1' day) as varchar)
                             and vendor_type = 'PC+Mobile'
                             and people_type <> '所有网民'
                             and cusid <> 2176274
                             and province = '中国大陆'
                             and vendor_name = ''
                           group by 1, 2
                       ) a
                           left join
                       (select order_id, group_concat(distinct imp_info) as imp_info
                        from u6rds.fancy_creative.monitor
                        group by 1
                       ) mnt on mnt.imp_info like concat('%', cast(cusid as varchar), '%')
              ) t
                  join
              (
                  select od.order_id,
                         od.order_name,
                         ln.name,
                         od.total_budget,
                         start_date,
                         end_date,
                         total_price
                  from u6rds.amo."order" od
                           left join u6rds.amo.alias_name ln
                                     on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
                  where order_system in (1, 2)
                    and od.status
                      > 1
                    and od.status
                      < 7
                    and order_id <> 588
                    and business_line in (1, 2, 3)
                    and end_date >= current_date - interval '1' day
              ) od on t.order_id = od.order_id
     ) t1
where people_type <> '稳定人群';



select t.order_id order_id, order_name, people_type, imp, ta_imp, sum(imp) over (partition by t.order_id) t_tol
from (
         select a.cusid,
                people_type,
                a.imp,
                a.ta_imp,
                o.order_id
         from (
                  select cusid,
                         people_type,
                         sum(case when people_type = '稳定人群' then imp else 0 end)  as imp,
                         sum(case when people_type <> '稳定人群' then imp else 0 end) as ta_imp
                  from u6rds.rpt_fancy.rpt_mz_reach_accumulate
                  where end_dt = '2020-10-09'
--                         cast((current_date - interval '1' day) as varchar)
                    and vendor_type = 'PC+Mobile'
                    and people_type <> '所有网民'
                    and cusid <> 2176274
                    and province = '中国大陆'
                    and vendor_name = ''
                  group by 1, 2
              ) a
                  left join
              (select order_id, activity_id
               from u6rds.amo."order"
--                    group by 1
              ) o on o.activity_id = cast(a.cusid as varchar)
     ) t
         join
     (
         select od.order_id,
                od.order_name,
                ln.name,
                od.total_budget,
                start_date,
                end_date,
                total_price
         from u6rds.amo."order" od
                  left join u6rds.amo.alias_name ln
                            on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
         where order_system in (1, 2)
           and od.status
             > 1
           and od.status
             < 7
           and order_id <> 588
           and business_line in (1, 2, 3)
           and end_date >= current_date - interval '1' day
     ) od on t.order_id = od.order_id



select order_id                       "订单ID",
       order_name                     "订单名称",
       people_type                    "人群类型",
       cast(ta_imp as double) / t_tol "TA浓度"
from (
         select t.order_id order_id, order_name, people_type, imp, ta_imp, sum(imp) over (partition by t.order_id) t_tol
         from (
                  select a.cusid,
                         people_type,
                         a.imp,
                         a.ta_imp,
                         o.order_id
                  from (
                           select cusid,
                                  people_type,
                                  sum(case when people_type = '稳定人群' then imp else 0 end)  as imp,
                                  sum(case when people_type <> '稳定人群' then imp else 0 end) as ta_imp
                           from u6rds.rpt_fancy.rpt_mz_reach_accumulate
                           where end_dt = '2020-11-26'
--                         cast((current_date - interval '1' day) as varchar)
                             and vendor_type = 'PC+Mobile'
                             and people_type <> '所有网民'
                             and cusid <> 2176274
                             and province = '中国大陆'
                             and vendor_name = ''
                           group by 1, 2
                       ) a
                           left join
                       (select order_id, activity_id
                        from u6rds.amo."order"
                       ) o on o.activity_id = cast(a.cusid as varchar)
                  where (imp <> 0 or ta_imp <> 0)
              ) t
                  join
              (
                  select od.order_id,
                         od.order_name,
                         ln.name,
                         od.total_budget,
                         start_date,
                         end_date,
                         total_price
                  from u6rds.amo."order" od
                           left join u6rds.amo.alias_name ln
                                     on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
                  where order_system in (1, 2)
                    and od.status
                      > 1
                    and od.status
                      < 7
                    and order_id <> 588
                    and business_line in (1, 2, 3)
                    and end_date >= current_date - interval '1' day
              ) od on t.order_id = od.order_id
     ) t1
where people_type <> '稳定人群'
  and order_name not like '%测试%'

order by 2, 3;


presto --execute "
with tag_sub as (
    select fancy_id
    from rpt.base_all_tags
    where source_id = '1'
      and thisdate = '2020-12-16'
      and (fancy_age in
           ('2600100002', '2600100003', '2600100004', '2600100005', '2600100006', '2600100007', '2600100008'))
)
        ,
     user_sub as (
         select user_id as uid, uid_type, mac, geo_code, '2003584' as advertiser_id, ua_id
         from rpt.base_device_ua_id_v2
         where thisdate = '2020-12-16'
           and ua_id not in ('0', '-1')
           and uid_type in ('1', '2', '3')
           and user_id not like 'M%'
           and (geo_code like '156001%' or geo_code like '156002%' or geo_code like '156003%' or geo_code in
                                                                                                 ('156006000001',
                                                                                                  '156006000002',
                                                                                                  '156005000001',
                                                                                                  '156005000002',
                                                                                                  '156011000001',
                                                                                                  '156020000001'))
     )
        ,
     ua_sub as (
         select distinct ua_id
         from u6rds.ad_fancy.base_ua_id_info
     )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
         left join
     (select ext_user_id
      from dwd.d_ad_impression
      where thisdate >= '2020-11-13'
        and ext_order_id in (2805, 2822, 2832)
     ) a
     on user_sub.uid = a.ext_user_id
where a.ext_user_id is null limit 20000000
" --output-format TSV > 1711__202012181117;"



select count(*)                                                          "差量",
       sum(case when a.user_agent like '%Android 11%' then 1 else 0 end) "安卓11",
       sum(case when a.user_agent like '%Android 10%' then 1 else 0 end) "安卓10",
       sum(case when a.user_agent like '%Android 9%' then 1 else 0 end)  "安卓9",
       sum(case when a.user_agent like '%Android 8%' then 1 else 0 end)  "安卓8",
       sum(case when a.user_agent like '%Android 7%' then 1 else 0 end)  "安卓7",
       sum(case when a.user_agent like '%Android 6%' then 1 else 0 end)  "安卓6",
       sum(case when a.user_agent like '%Android 5%' then 1 else 0 end)  "安卓5",
       sum(case when a.user_agent like '%Android 4%' then 1 else 0 end)  "安卓4"
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-17'
           and ext_vendor_id = 199
           and ext_advertiser_id = 2003574
           and ext_dsp_adgroup_id = 242194
     ) a
         left join
     (
         select *
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-17'
           and ext_advertiser_id = 2003574
           and ext_dsp_adgroup_id = 242194
           and ext_vendor_id = 199
     ) b
     on a.ext_request_id = b.ext_request_id
where b.ext_request_id is null limit 100



select count(*),
       sum(case when user_agent like '%Android 1%')
from dwd.d_ad_ftx_click_data
where thisdate = '2020-12-17'
  and ext_advertiser_id = 2003574
  and ext_dsp_adgroup_id = 242194
  and ext_vendor_id = 199

select count(*)
from dwd.d_ad_impression
where thisdate = '2020-12-17'
  and ext_advertiser_id = 2003574
  and ext_adgroup_id = 242194
  and ext_vendor_id = 199

select count(*)
from dwd.d_ad_ftx_impression_data
where thisdate = '2020-12-17'
  and ext_advertiser_id = 2003574
  and dsp_adgroup_id = 242194
  and ext_vendor_id = 199


select count(*)                                                        "差量",
       sum(case when user_agent like '%Android 11%' then 1 else 0 end) "安卓11",
       sum(case when user_agent like '%Android 10%' then 1 else 0 end) "安卓10",
       sum(case when user_agent like '%Android 9%' then 1 else 0 end)  "安卓9",
       sum(case when user_agent like '%Android 8%' then 1 else 0 end)  "安卓8",
       sum(case when user_agent like '%Android 7%' then 1 else 0 end)  "安卓7",
       sum(case when user_agent like '%Android 6%' then 1 else 0 end)  "安卓6",
       sum(case when user_agent like '%Android 5%' then 1 else 0 end)  "安卓5",
       sum(case when user_agent like '%Android 4%' then 1 else 0 end)  "安卓4"
from dwd.d_ad_ftx_click_data
where thisdate = '2020-12-17'
  and ext_advertiser_id = 2003574
  and ext_dsp_adgroup_id = 242194
  and ext_vendor_id = 199


select *
from dws.s_ad_ftx_join
where thisdate = '2020-12-05' limit 100


select bid_data, dsp_request_data, dsp_response_data, response_data
from ods.o_ad_ftx_raw_log
where thisdate = '2020-12-06'
  and order_id = 41779 -- 5,6号
-- and order_id = 40251 -- 12号
-- and bid_data like '%ios%'
-- and bid_data like '%android%'
-- and response_data like '%render.alipay.com%'
-- and response_data not like '%render.alipay.com%'
    limit 100;

select count(*)
from dwd.d_ad_impression
where thisdate <= '2020-12-15'
  and thisdate >= '2020-12-14'
  and ext_advertiser_id = 2003397
  and



select *
from (
         select case when b.geo_b_id is null then c.area_name else b.area_name end city, count(distinct ext_request_id)
         from dwd.d_ad_impression a
                  left join dim.dim_area b
                            on cast(a.ext_geo_id as varchar) = b.geo_b_id
                  left join dim.dim_area c
                            on cast(a.ext_geo_id as varchar) = cast(c.geo_id as varchar)
         where ext_advertiser_id = 2003553
           and thisdate <= '2020-12-20'
           and thisdate >= '2020-12-01'


         group by 1
         order by 2 desc limit 45) table1
         inner join

     (
         select case when b.geo_b_id is null then c.area_name else b.area_name end city, count(distinct ext_request_id)
         from dwd.d_ad_clicklog_day a
                  left join (select area_name, geo_b_id
                             from dim.dim_area
         ) b
                            on cast(a.ext_geo_id as varchar) = b.geo_b_id
                  left join dim.dim_area c
                            on cast(a.ext_geo_id as varchar) = cast(c.geo_id as varchar)
         where ext_advertiser_id = 2003553
           and thisdate <= '2020-12-20'
           and thisdate >= '2020-12-01'
         group by 1
     ) table2
     on table1.city = table2.city
order by 2 desc;

select case
           when a.user_agent like '%Android 10%' then '安卓10'
           else '非'
           end "机型",
       count(a.ext_request_id)
from (
      (
          select *
          from dwd.d_ad_ftx_click_data
          where thisdate = '2020-12-22'
            and ext_slot_id = '36282471'
      ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id)
where b.ext_request_id is null
group by 1
order by 1;



select a.*, b.c
from (
         select thisdate, count(ext_request_id)
         from dwd.d_ad_ftx_click_data
         where thisdate >= '2020-12-18'
           and thisdate <= '2020-12-23'
           and ext_slot_id = '36282471'
         group by 1
     ) a
         left join
     (
         select thisdate, count(ext_request_id) c
         from dwd.d_ad_clicklog_day
         where thisdate >= '2020-12-18'
           and thisdate <= '2020-12-23'
           and ext_slot_id = '36282471'
         group by 1
     ) b
     on a.thisdate = b.thisdate
order by 1


select a.ignore_rule, count(a.ext_request_id)
from (
         select *
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id
where b.ext_request_id is null
group by 1
order by 1


select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate, count(*) as dsp_click, count(distinct ext_request_id) as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
         order by 1
     ) a
         left join
     (
         select thisdate, count(*) as ftx_click, count(distinct ext_request_id) as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
         order by 1
     ) b on a.thisdate = b.thisdate
order by 1



select if(a.ext_request_id is not null, not_mozilla, -1)        as not_mozilla,
       sum(if(a.ext_request_id is not null, m_click, 0))        as m_click,
       sum(if(a.ext_request_id is not null, ok_click, 0))       as ok_click,
       sum(if(a.ext_request_id is not null, IqiyiApp_click, 0)) as IqiyiApp_click,
       sum(if(a.ext_request_id is not null, dsp_click, 0))      as dsp_click,
       sum(if(a.ext_request_id is not null, ftx_click, 0))      as ftx_click
from (
         select ext_request_id,
                max(if(strpos(user_agent, 'Mozilla') <> 0, 0, 1))  as not_mozilla,
                sum(if(strpos(user_agent, 'Mozilla') <> 0, 1, 0))  as m_click,
                sum(if(strpos(user_agent, 'okhttp') <> 0, 1, 0))   as ok_click,
                sum(if(strpos(user_agent, 'IqiyiApp') <> 0, 1, 0)) as IqiyiApp_click,
                sum(1)                                             as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
     ) a
         full outer join
     (
         select ext_request_id, sum(1) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
     ) b on a.ext_request_id = b.ext_request_id
group by 1

select ext_ip, ip, count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'
group by 1, 2
order by 3 desc

select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate,
                case when length(ext_user_id) = 32 then 'android' when length(ext_user_id) = 36 then 'ios' end as name,
                count(*)                                                                                       as dsp_click,
                count(distinct ext_request_id)                                                                 as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1, 2
         order by 1, 2
     ) a
         left join
     (
         select thisdate,
                case when ext_mobile_platform = 2 then 'android' when ext_mobile_platform = 1 then 'ios' end as name,
                count(*)                                                                                     as ftx_click,
                count(distinct ext_request_id)                                                               as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1, 2
         order by 1, 2
     ) b on a.thisdate = b.thisdate and a.name = b.name
order by 1, 2

select a.hour, dsp_click, ftx_click
from (
         select split(split(time, ' ')[2], ':')[1] as hour,count(*) as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
           and strpos(user_agent
             , 'Mozilla')=0
         group by 1
     ) a
         left join
     (
         select split(split(timestamp, ' ')[2], ':')[1] as hour,count(*) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
           and strpos(user_agent
             , 'Mozilla')=0
         group by 1
     ) b on a.hour = b.hour
order by 1


select thisdate, ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'
group by 1, 2
order by 1, 2

select count(ext_request_id)
from dwd.d_ad_ftx_click_data
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'

select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate, count(*) as dsp_click, count(distinct ext_request_id) as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
         order by 1
     ) a
         left join
     (
         select thisdate, count(*) as ftx_click, count(distinct ext_request_id) as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1
         order by 1
     ) b on a.thisdate = b.thisdate
order by 1

select thisdate,
       case
           when ext_vendor_id in (147, 118) then '韩剧tv'
           when ext_vendor_id in (27, 28, 57, 58) then '腾讯'
           when ext_vendor_id in (29, 30) then '爱奇艺'
           else cast(ext_vendor_id as varchar)
           end as vendor,
       count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'
group by 1, 2
order by 1, 2

select a.ext_advertiser_id,
       count(a.ext_request_id)
from (
      (
          select *
          from dwd.d_ad_ftx_click_data
          where thisdate = '2020-12-22'
            and ext_slot_id = '36282471'
      ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id)
where b.ext_request_id is null
group by 1
order by 1;

select ext_ip, ip, count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'
group by 1, 2
order by 3 desc;

select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate,
                case when length(ext_user_id) = 32 then 'android' when length(ext_user_id) = 36 then 'ios' end as name,
                count(*)                                                                                       as dsp_click,
                count(distinct ext_request_id)                                                                 as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1, 2
         order by 1, 2
     ) a
         left join
     (
         select thisdate,
                case when ext_mobile_platform = 2 then 'android' when ext_mobile_platform = 1 then 'ios' end as name,
                count(*)                                                                                     as ftx_click,
                count(distinct ext_request_id)                                                               as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
         group by 1, 2
         order by 1, 2
     ) b on a.thisdate = b.thisdate and a.name = b.name
order by 1, 2

select case when length(a.ext_user_id) = 32 then 'android' when length(a.ext_user_id) = 36 then 'ios' end "机型",
       count(a.ext_request_id)
from (
      (
          select *
          from dwd.d_ad_ftx_click_data
          where thisdate = '2020-12-22'
            and ext_slot_id = '36282471'
      ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id)
where b.ext_request_id is null
group by 1
order by 1;

select a.hour, dsp_click, ftx_click
from (
         select split(split(time, ' ')[2], ':')[1] as hour,count(*) as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
           and strpos(user_agent
             , 'Mozilla')=0
         group by 1
     ) a
         left join
     (
         select split(split(timestamp, ' ')[2], ':')[1] as hour,count(*) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
           and strpos(user_agent
             , 'Mozilla')=0
         group by 1
     ) b on a.hour = b.hour
order by 1

select substring(a.user_agent, 1, 1),
       count(a.ext_request_id)
from (
      (
          select *
          from dwd.d_ad_ftx_click_data
          where thisdate = '2020-12-22'
            and ext_slot_id = '36282471'
      ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id)

group by 1
order by 1;

select *
from dwd.d_ad_ftx_click_data
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471' limit 100

select *
from (
      (
          select *
          from dwd.d_ad_ftx_click_data
          where thisdate = '2020-12-22'
            and ext_slot_id = '36282471'
      ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id)
where b.ext_request_id is null limit 100

select a.thisdate, count(a.ext_request_id) ftx_click, count(b.ext_request_id) dsp_click
from dwd.d_ad_ftx_click_data a,
     dwd.d_ad_clicklog_day b
where a.thisdate >= '2020-12-18'
  and a.thisdate <= '2020-12-23'
  and a.ext_slot_id = '36282471'
  and b.ext_slot_id = '36282471'
  and b.thisdate >= '2020-12-18'
  and b.thisdate <= '2020-12-23'
group by 1
order by 1

select thisdate, count(ext_request_id)
from dwd.d_ad_ftx_click_data
where thisdate >= '2020-12-18'
  and thisdate <= '2020-12-23'
  and ext_slot_id = '36282471'
group by 1
order by 1



create view langqing as
(
select a.*
from (
         select *
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id
where b.ext_request_id is not null)


select c.*
from (
         select *
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id
         left join
     (
         select *
         from ods.o_ad_ftx_raw_log
         where thisdate = '2020-12-22'
           and slot_id = '36282471'
     ) c
     on a.ext_request_id = c.request_id
where c.request_id is not null
  and b.ext_request_id is not null limit 50


select *
from (
         select cid, timestamp, ext_timestamp as cur_time
                 , row_number() over (PARTITION BY cid ORDER BY ext_timestamp) as rn
                 , LAG(ext_timestamp, 1, '1970-01-01 00:00:00') OVER(PARTITION BY cid ORDER BY ext_timestamp) as pre_time
         from
             (
             select ext_request_id, ext_vendor_id, max (cid) as cid
                 , max (timestamp) as timestamp
                 , max (ext_timestamp) as ext_timestamp
             from d_ad_impression
             where thisdate = '2020-12-22'
             and slot_id = '36282471'
             group by ext_request_id, ext_vendor_id
             ) b
     ) a
where rn in (7, 8)


select count(a.ext_request_id)
from (
         select *
         from dwd.d_ad_ftx_click_data
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) a
         left join
     (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2020-12-22'
           and ext_slot_id = '36282471'
     ) b
     on a.ext_request_id = b.ext_request_id
where b.ext_request_id is null
  and b.ext_ad_id = 458243


select ext_spot_id, count(ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2020-12-22'
  and ext_slot_id = '36282471'
group by 1
order by 1


select pinci, count(uid)
from (
         select ext_user_id uid, count(ext_request_id) pinci
         from dwd.d_ad_impression
         where thisdate = '2020-12-25'
           and ext_order_id = 2922
         group by 1
     ) a
group by 1
order by 1

select thisdate,
       ext_slot_id,
       count(distinct ext_request_id)                                                as imp,
       sum(cost_price * 1.000000000 / 1000000000)                                    as cost,
       count(distinct if(ext_bid_price = cost_price, ext_request_id, null))          as yijia_imp,
       sum(if(ext_bid_price = cost_price, cost_price * 1.000000000 / 1000000000, 0)) as yijia_cost
from dwd.d_ad_ftx_win_data
where thisdate >= '2020-11-21'
  and thisdate <= '2020-11-30'
  and ext_vendor_id = 120
  and (ext_adx_bid_tag = '' or ext_adx_bid_tag is null)
group by 1, 2;

with tag_sub as (
    select fancy_id
    from rpt.base_all_tags
    where source_id = '1'
      and thisdate = '2020-12-23'
      and (fancy_age in
           ('2600100002', '2600100003', '2600100004', '2600100005', '2600100006', '2600100007', '2600100008',
            '2600100009'))
)
        ,
     user_sub as (
         select user_id as uid, uid_type, mac, geo_code, '2003584' as advertiser_id, ua_id
         from rpt.base_device_ua_id_v2
         where thisdate = '2020-12-23'
           and ua_id not in ('0', '-1')
           and uid_type in ('1', '2', '3')
           and user_id not like 'M%'
           and (geo_code like '156001%' or geo_code like '156002%' or
                geo_code in ('156006000001', '156005000001', '156005000002'))
     )
        ,
     ua_sub as (
         select distinct ua_id
         from u6rds.ad_fancy.base_ua_id_info
     )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id limit 20000000


第一波广告主：2003513
第一波AMO订单：2464
投放时间：2020-08-06-2020-10-15

本波广告主：2003584
本波AMO订单：2805
投放时间：2020-11-13-2020-12-31

地域：北上广深杭

需求：找出第一波看过但本波未看过的设备ID



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


select *
from dwd.d_ad_ftx_request limit 1


presto --execute "
with
tag_sub as (
    select fancy_id from rpt.base_all_tags
    where source_id = '1' and thisdate = '2021-03-17'
    and (fancy_age in ('2600100003','2600100004','2600100005','2600100006'))
    and (fancy_gender in ('2500100020'))
    limit 200000000
)

    ,
user_sub as (
    select user_id as uid,uid_type, mac ,geo_code,'2003074' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where  thisdate = '2021-03-18' and ua_id not in ('0','-1') and uid_type in ('1','2','3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
)

    ,
ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
)

select user_sub.uid as user_id
    ,user_sub.uid_type
    ,'528C8E6CD4A3C6598999A0E9DF15AD32' as mac
    , user_sub.geo_code
    , user_sub.advertiser_id
    , user_sub.ua_id
from   tag_sub join user_sub on tag_sub.fancy_id = user_sub.uid  join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type='3'
union all
select user_sub.uid as user_id
    ,user_sub.uid_type
    ,'528C8E6CD4A3C6598999A0E9DF15AD32' as mac
    , user_sub.geo_code
    , user_sub.advertiser_id
    , user_sub.ua_id
from   tag_sub join user_sub on tag_sub.fancy_id = user_sub.uid  join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1','2')
limit 20000000" --output-format TSV > ip_202012282011;"

datediff(MINUTE,cast(ext_timestamp as datetime), cast ("timestamp" as datetime));


select thisdate,
       count(ext_request_id)
from dwd.d_ad_ftx_win_data
where ext_order_id in (33446, 33511, 33924, 33925, 33926, 33927)
  and thisdate >= '2020-11-01'
  and thisdate <= '2020-11-30'
  and date_diff('second', cast(ext_timestamp as timestamp), cast("timestamp" as timestamp)) >= 5
group by 1
order by 1 1728__202012301122

awk '{if(substr($6,9,4)<2112 && $2==1) {print $0}}' 1728__202012301122 > linshi1
awk '{if(substr($6,9,4)>=2112 && substr($6,9,4)<4000 && $2==3) {print $0}}' 1728__202012301122 > linshi2
awk '{if(substr($6,9,4)>4000 && $2==2) {print $0}}' 1728__202012301122 > linshi3
cat linshi1 linshi2 linshi3 >1728__202012301155




presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where source_id = '1' and thisdate = '2020-12-28'
    and (fancy_age in ('2600100003', '2600100004', '2600100005', '2600100006'))
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '2003558' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2020-12-28' and ua_id not in ('0', '-1') and uid_type in ('1', '2', '3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id limit 20000000
" --output-format TSV > 1729__202012301509;"




presto --execute "
with
    tag_sub as (
    select uid
    from rpt.base_nequal_uid_tags
    where thisdate = '2020-12-16'
    and (mz_gender in ('2500100020')
    or qtt_gender in ('2500100020')
    or wb_gender in ('2500100020') )
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
    where thisdate = '2020-12-28' and ua_id not in ('0', '-1') and uid_type in ('1', '2', '3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.uid = user_sub.uid limit 20000000
" --output-format TSV > 1729__202012301521;"


select thisdate,
       case
           when b.geo_b_id like '156007%' then '江苏'
           when b.geo_b_id like '156017%' then '安徽'
           when b.geo_b_id like '156006%' then '浙江'
           else '其他' end,
       case
           when a.pc = 1 then '1'
           when a.pc = 2 then '2'
           when a.pc = 3 then '3'
           when a.pc = 4 then '4'
           when a.pc = 5 then '5'
           when a.pc = 6 then '6'
           else '7+' end,
       sum(pc)              "超频频次",
       count(a.ext_user_id) "超频人数"
from (
         select thisdate, ext_user_id, ext_geo_id, count(ext_request_id) pc
         from dwd.d_ad_impression
         where ext_order_id = 2942
           and thisdate >= '2020-12-28'
           and thisdate <= '2021-01-05'
         group by 1, 2, 3
     ) a
         left join dim.dim_area b
                   on cast(a.ext_geo_id as varchar) = b.geo_b_id
group by 1, 2, 3
order by 1, 2, 3


select thisdate,
       case
           when geo_b_id like '156007%' then '江苏'
           when geo_b_id like '156017%' then '安徽'
           when geo_b_id like '156006%' then '浙江'
           else '其他' end
        ,
       count(ext_request_id) - count(distinct ext_request_id) as "重复上报"
from dwd.d_ad_impression a
         left join dim.dim_area b
                   on cast(a.ext_geo_id as varchar)
                       = b.geo_b_id
where ext_order_id = 2942
  and thisdate >= '2020-12-28'
  and thisdate <= '2021-01-05'
group by 1, 2
order by 1, 2



select thisdate,
       case
           when geo_b_id like '156007%' then '江苏'
           when geo_b_id like '156017%' then '安徽'
           when geo_b_id like '156006%' then '浙江'
           else '其他' end
        ,
       count(ext_request_id) as "曝光"
from dwd.d_ad_impression a
         left join dim.dim_area b
                   on cast(a.ext_geo_id as varchar)
                       = b.geo_b_id
where ext_order_id = 2942
  and thisdate >= '2020-12-28'
  and thisdate <= '2021-01-05'
group by 1, 2;

presto --execute "
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

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.uid = user_sub.uid limit 20000000
" --output-format TSV > 1746__202101071131;"

select a.thisdate, a.slot, a.imp ftximp, b.imp dspimp
from (
         select thisdate
              -- , substring(cast(ext_geo_id as varchar), 1, 6) geo
              , ext_slot_id           slot
              , count(ext_request_id) imp
         from d_ad_ftx_impression_data
         where thisdate = '2021-01-06'
           and ext_ad_id = 458908
         group by 1, 2) a
         left join
     (
         select thisdate
              -- , substring(cast(ext_geo_id as varchar), 1, 6) geo
              , ext_slot_id           slot
              , count(ext_request_id) imp
         from d_ad_impression
         where thisdate = '2021-01-06'
           and ext_ad_id = 458908
         group by 1, 2
     ) b
     on a.slot = b.slot


select thisdate
     -- , substring(cast(ext_geo_id as varchar), 1, 6) geo
     , ext_vendor_id         vendor
     , case
           when user_agent like '%Android%' then 'anzhuo'
           when user_agent like '%OS%' then 'ios'
           else 'qita' end
     , count(ext_request_id) imp
from d_ad_impression
where thisdate = '2021-01-06'
  and ext_ad_id = 458908
  and ext_slot_id not in ('10000670', '10000669')
group by 1, 2, 3

select thisdate, ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate = '2021-01-06'
  and ext_ad_id = 458908
group by 1, 2
order by 1, 2


select a.rn,
       sum(case
               when date_diff('second', cast(replace(pre_time, '_', ' ') as timestamp),
                              cast(replace(cur_time, '_', ' ') as timestamp)) <= 20 then 1
               else 0 end) jjcp,
       sum(case
               when date_diff('second', cast(replace(pre_time, '_', ' ') as timestamp),
                              cast(replace(cur_time, '_', ' ') as timestamp)) > 20 then 1
               else 0 end)
from (
         select cid, timestamp, ext_timestamp as cur_time
                 , row_number() over (PARTITION BY cid ORDER BY ext_timestamp) as rn
                 , LAG(ext_timestamp, 1, '1970-01-01 00:00:00') OVER(PARTITION BY cid ORDER BY ext_timestamp) as pre_time
         from
             (
             select ext_request_id, ext_vendor_id, max (cid) as cid
                 , max (timestamp) as timestamp
                 , max (ext_timestamp) as ext_timestamp
             from d_ad_impression
             where ext_order_id = 2942
             and thisdate >= '2020-12-28'
             and thisdate <= '2021-01-06'
             group by ext_request_id, ext_vendor_id
             ) b
     ) a
where rn in (7, 8, 9, 10)
group by 1


select thisdate
     , sum(case when qq > 6 then 1 else 0 end)   cprs
     , sum(case when qcqq > 6 then 1 else 0 end) qccprs
from (
         select thisdate,
                p_name_b                       geo,
                ext_user_id                    uid,
                count(ext_request_id)          qq,
                count(distinct ext_request_id) qcqq
                -- count(ext_request_id) - count(distinct ext_request_id) "重复上报"
         from dwd.d_ad_impression a
                  left join dim.dim_area b
                            on cast(a.ext_geo_id as varchar)
                                = b.geo_b_id
         where ext_order_id = 2942
           and thisdate >= '2020-12-28'
           and thisdate <= '2021-01-07'
         group by 1, 2, 3
     )
group by 1;


select geo,
       case
           when pc = 1 then '1'
           when pc = 2 then '2'
           when pc = 3 then '3'
           when pc = 4 then '4'
           when pc = 5 then '5'
           when pc = 6 then '6'
           else '7+' end,
       sum(pc)            "频次",
       count(ext_user_id) "人数"
from (
         select ext_user_id,
                case
                    when geo_b_id like '156007%' then '江苏'
                    when geo_b_id like '156017%' then '安徽'
                    when geo_b_id like '156006%' then '浙江'
                    else '其他' end     geo,
                count(ext_request_id) pc
         from dwd.d_ad_impression a
                  left join dim.dim_area b
                            on cast(a.ext_geo_id as varchar) = b.geo_b_id
         where ext_order_id = 2942
           and thisdate >= '2020-12-28'
           and thisdate <= '2021-01-05'
         group by 1, 2)
group by 1, 2
union all
select geo,
       '总和',
       sum(pc)            "频次",
       count(ext_user_id) "人数"
from (
         select ext_user_id,
                case
                    when geo_b_id like '156007%' then '江苏'
                    when geo_b_id like '156017%' then '安徽'
                    when geo_b_id like '156006%' then '浙江'
                    else '其他' end     geo,
                count(ext_request_id) pc
         from dwd.d_ad_impression a
                  left join dim.dim_area b
                            on cast(a.ext_geo_id as varchar) = b.geo_b_id
         where ext_order_id = 2942
           and thisdate >= '2020-12-28'
           and thisdate <= '2021-01-05'
         group by 1, 2
     )
group by 1, 2
order by 1, 2



select substring(ip, 1, 8),
       ext_ip,
       count(ext_request_id)
from dwd.d_ad_ftx_impression_data
where ext_ad_id = 459443
  and thisdate >= '2021-01-05'
  and thisdate <= '2021-01-06'
  and ip <> ext_ip
  and substring(ip, 1, 8) = '125.210.'
group by 1, 2

select referer, anonymous_ua, ext_mobile_idfa, ext_mobile_imei_md5, ext_mobile_oaid
from dwd.d_ad_impression
where thisdate = '2021-01-14'
  and ext_ad_id = 460137 limit 100


select count(referer), sum(if(referer is null or referer = '', 1, 0))
from dwd.d_ad_impression
where thisdate = '2021-01-14'
  and ext_ad_id = 460137 desc dwd.d_ad_ftx_impression_data



select ext_user_id
from dwd.d_ad_ftx_impression_data
where thisdate <= '2021-01-18'
  and thisdate >= '2020-01-18'
  and ext_dsp_id in (78, 89, 25)
group by 1 presto --execute "
with
    tag_sub as (
    select uid
    from rpt.base_nequal_uid_tags
    where thisdate = '2020-12-16'
    and (mz_gender in ('2500100020')
    or qtt_gender in ('2500100020')
    or wb_gender in ('2500100020') )
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
    where thisdate = '2021-01-17' and ua_id not in ('0', '-1') and uid_type in ('1', '2', '3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 1000000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.uid = user_sub.uid limit 20000000
" --output-format TSV > 1746__202101191046;"


select count(*)
from dwd.d_ad_action
where vendorid = '227'
  and thisdate = '2021-01-20'
  and action ='land'

select count(*)
from dwd.d_ad_clicklog_day
where ext_vendor_id = 227
  and thisdate = '2021-01-20'



select a.ext_slot_id, count(a.ext_request_id), sum(if(b.ext_request_id is null, 1, 0))
from dwd.d_ad_clicklog_day a
         left join dwd.d_ad_ftx_click_data b
                   on a.ext_request_id = b.ext_request_id
where a.thisdate >= '2021-01-11'
  and a.thisdate <= '2021-01-13'
  and a.ext_ad_id in
      (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907, 459913,
       459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793, 459898,
       459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955, 459796,
       459795, 459931
          )
group by 1


select count(ext_request_id)
from dwd.d_ad_impression a
-- join u6rds.ftx.order_detail_amo_order b
-- on a.ext_order_id = b.order_id
where thisdate = '2021-01-11'
--   and thisdate <= '2021-01-13'
  and a.ext_ad_id in
      (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907, 459913,
       459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793, 459898,
       459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955, 459796,
       459795, 459931
          )


select thisdate, ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate between '2021-01-11' and '2021-01-13'
  and ext_ad_id in
      (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907, 459913,
       459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793, 459898,
       459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955, 459796,
       459795, 459931
          )
group by 1, 2
order by 1, 2


select m_app_version,
       ext_request_id,
       ext_time, time, to_unixtime(cast (replace(time, '_', ' ') as timestamp))-q_time as jg
from
    (
    select b.m_app_version, a.ext_request_id, a.ext_time, a.time,
    lag(to_unixtime(cast (replace(a.time, '_', ' ') as timestamp))) over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as q_time,
    row_number() over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as num
    from dwd.d_ad_clicklog_day a inner join dwd.d_ad_request b on a.ext_request_id=b.request_id
    where a.thisdate between '2021-01-11' and '2021-01-13'
    and ext_ad_id in
    (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907, 459913,
    459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793, 459898,
    459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955, 459796,
    459795, 459931
    )
    ) a
where num>1

select if(a.ext_request_id is not null, not_mozilla, -1)        as not_mozilla,
       sum(if(a.ext_request_id is not null, m_click, 0))        as m_click,
       sum(if(a.ext_request_id is not null, ok_click, 0))       as ok_click,
       sum(if(a.ext_request_id is not null, IqiyiApp_click, 0)) as IqiyiApp_click,
       sum(if(a.ext_request_id is not null, dsp_click, 0))      as dsp_click,
       sum(if(a.ext_request_id is not null, ftx_click, 0))      as ftx_click
from (
         select ext_request_id,
                max(if(strpos(user_agent, 'Mozilla') <> 0, 0, 1))  as not_mozilla,
                sum(if(strpos(user_agent, 'Mozilla') <> 0, 1, 0))  as m_click,
                sum(if(strpos(user_agent, 'okhttp') <> 0, 1, 0))   as ok_click,
                sum(if(strpos(user_agent, 'IqiyiApp') <> 0, 1, 0)) as IqiyiApp_click,
                sum(1)                                             as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate between '2021-01-11' and '2021-01-13'
           and ext_ad_id in
               (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907,
                459913,
                459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793,
                459898,
                459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955,
                459796,
                459795, 459931
                   )
         group by 1
     ) a
         full outer join
     (
         select ext_request_id, sum(1) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate between '2021-01-11' and '2021-01-13'
           and ext_ad_id in
               (459891, 459890, 459885, 459790, 459929, 459949, 459935, 459900, 459906, 459945, 459912, 459933, 459907,
                459913,
                459896, 459883, 459792, 459932, 459937, 459921, 459794, 459788, 459901, 459899, 459930, 459791, 459793,
                459898,
                459946, 459934, 459897, 459884, 459789, 459954, 459953, 459944, 459922, 459920, 459797, 459936, 459955,
                459796,
                459795, 459931
                   )
         group by 1
     ) b on a.ext_request_id = b.ext_request_id
group by 1]


select distinct fancy_id
from rpt.base_all_tags
where thisdate = '2021-01-20'
  and fancy_gender = '2500100020'
  and length(fancy_id) = 36


-- 定向
select a.thisdate,
       a.ext_vendor_id,
       count(distinct a.ext_request_id)
from dwd.d_ad_clicklog_day a
         left join dwd.d_ad_ftx_click_data b
                   on a.ext_request_id = b.ext_request_id
where a.thisdate between '2021-01-11' and '2021-01-13'
  and a.ext_ad_id in
      (
       459920,
       459921,
       459922,
       459929,
       459930,
       459931,
       459932,
       459933,
       459934,
       459935,
       459936,
       459937,
       459944,
       459945,
       459946,
       459953,
       459954,
       459955)
  and b.ext_request_id is null
group by 1, 2
order by 1, 2

-- 全国
select a.*
from dwd.d_ad_clicklog_day a
         left join dwd.d_ad_ftx_click_data b
                   on a.ext_request_id = b.ext_request_id
where a.thisdate = '2021-01-11'
  and a.ext_ad_id in
      (459890,
       459896,
       459898,
       459900,
       459906,
       459912)
  and b.ext_request_id is not null


select slot_id, count(*)
from dwd.d_ad_action
where vendorid = '227'
  and thisdate = '2021-01-22'
  and action ='land'
group by 1



select ext_slot_id, count(*)
from dwd.d_ad_clicklog_day
where ext_vendor_id = 227
  and thisdate = '2021-01-22'
group by 1

select a.*
from dwd.d_ad_clicklog_day a
         left join dwd.d_ad_ftx_click_data b
                   on a.ext_request_id = b.ext_request_id
where a.thisdate = '2021-01-11'
  and a.ext_ad_id in
      (459896,
       459890,
       459898,
       459900,
       459906,
       459912)
  and b.ext_request_id is not null


select *
from d_ad_ftx_click_data
where thisdate = '2021-01-22'
  and ext_ad_id = 6158
-- group by ignore_rule;

select id,
       s30                       "0-30秒",
       1.0000 * s30 / t          "0-30秒该用户占比",
       s60 - s30                 "30-60秒",
       1.0000 * (s60 - s30) / t  "30-60秒该用户占比",
       s120 - s60                "60-120秒",
       1.0000 * (s120 - s60) / t "60-120秒该用户占比",
       s121,
       1.0000 * s121 / t,
       t
from (
         select ext_user_id         id,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 5 or date_diff('second', p_time, time) <= 5 then 1
--                         else 0 end) s5,
--                 sum(case
--                         when date_diff('second', time, a_time) <= 10 or date_diff('second', p_time, time) <= 10 then 1
--                         else 0 end) s10,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 30 then 1
                        else 0 end) s30,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 60 then 1
                        else 0 end) s60,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 120 then 1
                        else 0 end) s120,
                sum(case
                        when if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
                                date_diff('second', p_time, time), date_diff('second', time, a_time)) > 120 then 1
                        else 0 end) s121,
                sum(imp)            t
         from (
                  select ext_user_id, time
                          , lag(time, 1, cast ('1970-01-01 00:00:00' as timestamp )) over(partition by ext_ad_id, ext_user_id order by time) as p_time
                          , lead(time, 1, cast ('2099-12-31 23:59:59' as timestamp )) over(partition by ext_ad_id, ext_user_id order by time) as a_time
                          , 1 as imp
                  from
                      (
                      select ext_ad_id, ext_user_id
                      -- timestamp imp, time click
                          , cast (replace(timestamp, '_', ' ') as timestamp) as time
                      from dwd.d_ad_ftx_click_data a
                      -- a.ext_slot_id in ('36282056', '36282251')-- 36282056, 36282251,36282610', '36282620
                      where thisdate='2021-01-22'
                      and ext_ad_id = 6158
                      -- imp
                      -- and hour = '19'
                      -- click
                      -- and time >= '2021-01-20 19:00:00'
                      -- and time < '2021-01-20 20:00:00'
                      ) a
              ) b
         group by 1
         order by 1
     )
order by 2 desc

-- 301948
select count(a.ext_user_id)
from (
         select ext_user_id
         from d_ad_ftx_click_data
         where thisdate = '2021-01-20'
     ) a
         left join (
    select bid_req_adx_dmp_rules, bid_req_user_id
    from dspv2_bidding_log
    where thisdate = '2021-01-21'
      and contains(bid_req_adx_dmp_rules, '301948')
) b
                   on a.ext_user_id = b.bid_req_user_id



select vendor                          "媒体",
       spot                            "点位",
       total_imp                       "曝光",
       total_uv                        UV,
       imp100plus                      "曝光100+",
       imp100plus * 1.0000 / total_imp "曝光100+占比",
       uv100plus                       "UV100+",
       uv100plus * 1.0000 / total_uv   "UV100+占比",
       imp50plus                       "曝光50+",
       imp50plus * 1.0000 / total_imp  "曝光50+占比",
       uv50plus                        "UV50+",
       uv50plus * 1.0000 / total_uv    "UV50+占比",
       imp20plus                       "曝光20+",
       imp20plus * 1.0000 / total_imp  "曝光20+占比",
       uv20plus                        "UV20+",
       uv20plus * 1.0000 / total_uv    "UV20+占比",
       imp10plus                       "曝光10+",
       imp10plus * 1.0000 / total_imp  "曝光10+占比",
       uv10plus                        "UV10+",
       uv10plus * 1.0000 / total_uv    "UV10+占比"

from (
         select vendor,
                spot,
                sum(uv * pv)                  total_imp,
                sum(uv)                       total_uv,
                sum(if(pv > 100, uv * pv, 0)) imp100plus,
                sum(if(pv > 100, uv, 0))      uv100plus,
                sum(if(pv > 50, uv * pv, 0))  imp50plus,
                sum(if(pv > 50, uv, 0))       uv50plus,
                sum(if(pv > 20, uv * pv, 0))  imp20plus,
                sum(if(pv > 20, uv, 0))       uv20plus,
                sum(if(pv > 10, uv * pv, 0))  imp10plus,
                sum(if(pv > 10, uv, 0))       uv10plus

         from (
                  select vendor,
                         spot,
                         pv,
                         count(distinct ext_user_id) uv

                  from (
                           select upper(b.vendor) vendor, b.spot, a.ext_user_id, count(distinct ext_request_id) as pv
                           from dwd.d_ad_ftx_impression_data a

                                    join
                                (
                                    select o.id, sp.spot, sp.vendor
                                    from u6rds.ftx."order" o
                                             join u6rds.rpt_fancy.temp_spot_shuang11_2020 sp
                                                  on o.parent_id = sp.id
                                    where sp.type = 'porder'
                                    group by 1, 2, 3
                                ) b
                                on a.ext_order_id = b.id
                           where a.thisdate = '2021-01-20'
                           group by 1, 2, 3
                       ) t
                  group by 1, 2, 3
              ) c
         group by 1, 2
     ) d

order by 1



select b.spot_id,
       a.ext_user_id,
       count(distinct ext_request_id) as pv
from dwd.d_ad_impression a
         join u6rds.ad_fancy.ad_group b on b.id = a.ext_adgroup_id and b.spot_id in (34624)
where a.thisdate = '2021-01-23'
  and ext_adgroup_id in (select id from u6rds.ad_fancy.ad_group where spot_id in (34624))
group by 1, 2
order by 3 desc



select ext_user_id id, p_time, a_time
from (
         select spot_id,
                ext_user_id, time
                 , lag(time, 1, cast ('1970-01-01 00:00:00' as timestamp )) over(partition by spot_id, ext_user_id order by time) as p_time
                 , lead(time, 1, cast ('2099-12-31 23:59:59' as timestamp )) over(partition by spot_id, ext_user_id order by time) as a_time
                 , 1 as imp
         from
             (
             select b.spot_id, ext_user_id
             -- timestamp imp, time click
                 , cast (replace(timestamp, '_', ' ') as timestamp) as time
             -- from dwd.d_ad_clicklog_day a
             from dwd.d_ad_impression a
             join u6rds.ad_fancy.ad_group b on b.id=a.ext_adgroup_id and b.spot_id in (34624)
             where thisdate='2021-01-25'
             ) a
     ) b
where if(date_diff('second', time, a_time) > date_diff('second', p_time, time),
         date_diff('second', p_time, time), date_diff('second', time, a_time)) <= 30
group by 1, 2, 3



select adid
     , sum(1)                                                  as pv
     , sum(if(diff_scds < 30, 1, 0))                           as inv_pv
     , round(1.00 * sum(if(diff_scds < 30, 1, 0)) / sum(1), 2) as ratio
from (
         select uid
              , adid
              , imp_time
              , pre_imp_time
              , date_diff('second', pre_imp_time, imp_time) as diff_scds
         from (
                  select uid
                       , adid
                       , imp_time
                       , lag(imp_time, 1, cast('1970-01-01 00:00:00' as timestamp)) over (partition by uid order by imp_time) as pre_imp_time
                  from (
                           select ext_user_id                                       as uid
                                , ext_ad_id                                         as adid
                                , cast(replace("timestamp", '_', ' ') as timestamp) as imp_time
                           from dwd.d_ad_impression a
                                    join u6rds.ad_fancy.ad_group b
                                         on b.id = a.ext_adgroup_id and b.spot_id in (34624)
                           where thisdate = '2021-01-25'
                             -- and "hour" = '13'
                             and ext_ad_id <> 460004
                       ) a
              ) b
     ) c
group by adid;



select order_id                       "订单ID",
       order_name                     "订单名称",
       people_type                    "人群类型",
       cast(ta_imp as double) / t_tol "TA浓度"
from (
         select t.order_id order_id, order_name, people_type, imp, ta_imp, sum(imp) over (partition by t.order_id) t_tol
         from (
                  select a.cusid,
                         people_type,
                         a.imp,
                         a.ta_imp,
                         o.order_id
                  from (
                           select cusid,
                                  people_type,
                                  sum(case when people_type = '稳定人群' then imp else 0 end)  as imp,
                                  sum(case when people_type <> '稳定人群' then imp else 0 end) as ta_imp
                           from u6rds.rpt_fancy.rpt_mz_reach_accumulate
                           where end_dt = '2021-02-18'
--                         cast((current_date - interval '1' day) as varchar)
                             and vendor_type = 'PC+Mobile'
                             and people_type <> '所有网民'
                             and cusid <> 2176274
                             and province = '中国大陆'
                             and vendor_name = ''
                           group by 1, 2
                       ) a
                           left join
                       (select order_id, activity_id
                        from u6rds.amo."order"
                       ) o on o.activity_id = cast(a.cusid as varchar)
                  where (imp <> 0 or ta_imp <> 0)
              ) t
                  join
              (
                  select od.order_id,
                         od.order_name,
                         ln.name,
                         od.total_budget,
                         start_date,
                         end_date,
                         total_price
                  from u6rds.amo."order" od
                           left join u6rds.amo.alias_name ln
                                     on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
                  where order_system in (1, 2)
                    and od.status
                      > 1
                    and od.status
                      < 7
                    and order_id <> 588
                    and business_line in (1, 2, 3)
                    and end_date >= cast('2021-02-18' as date)
              ) od on t.order_id = od.order_id
     ) t1
where people_type <> '稳定人群'
  and order_name not like '%测试%'
order by 2, 3


select od.order_id,
       od.order_name,
       ln.name,
       od.total_budget,
       start_date,
       end_date,
       total_price
from u6rds.amo."order" od
         left join u6rds.amo.alias_name ln
                   on od.advertiser_remark = cast(ln.id as varchar) and ln.type = 1
where order_system in (1, 2)
  and od.status
    > 1
  and od.status
    < 7
  and order_id <> 588
  and business_line in (1, 2, 3)
  and end_date >= cast('2021-02-18' as date)
  and order_id in (
                   2846,
                   2885,
                   2889,
                   2890,
                   2942,
                   2944,
                   2944,
                   2946,
                   2990,
                   2991,
                   3000,
                   3000,
                   3007,
                   3007,
                   3021,
                   3035,
                   3036,
                   3049,
                   3057,
                   3058,
                   3069,
                   3070,
                   3073)



select a.cusid,
       people_type,
       a.imp,
       a.ta_imp,
       o.order_id
from (
         select cusid,
                people_type,
                sum(case when people_type = '稳定人群' then imp else 0 end)  as imp,
                sum(case when people_type <> '稳定人群' then imp else 0 end) as ta_imp
         from u6rds.rpt_fancy.rpt_mz_reach_accumulate
         where end_dt = '2021-02-19'
--                         cast((current_date - interval '1' day) as varchar)
           and vendor_type = 'PC+Mobile'
           and people_type <> '所有网民'
           and cusid <> 2176274
           and province = '中国大陆'
           and vendor_name = ''
         group by 1, 2
     ) a
         left join
     (select order_id, activity_id
      from u6rds.amo."order"
     ) o on o.activity_id = cast(a.cusid as varchar)
where (imp <> 0 or ta_imp <> 0)
  and order_id in (
                   2942,
                   2990,
                   3057,
                   3058,
                   2991,
                   2889,
                   2890
    )


select ext_vendor_id,
       if(clk_up_x_point > 0 or clk_up_y_point > 0, 1, 0),
       count(1)
from d_ad_ftx_click_data
where thisdate = '2021-02-18'
  and (user_agent like '%OPPO%' or user_agent like '%oppo%')
--   and ext_vendor_id in (110,
--                         112,
--                         118,
--                         120,
--                         153,
--                         199,
--                         204,
--                         222,
--                         223,
--                         225,
--                         229,
--                         230,
--                         231,
--                         235,
--                         238,
--                         241,
--                         242,
--                         243,
--                         246)
group by 1, 2
order by 1, 2



select city,
       case when pv <= 6 then pv else 7 end as pinci,
       count(1)                             as uv,
       sum(pv)                              as pv
from (
         select replace(case when city is null then c.area_name else b.city end, '市')            as city,
                if(ext_user_id is null or ext_user_id = '', concat(ip, user_agent), ext_user_id) as user_id,
                count(distinct ext_request_id)                                                   as pv
         from dwd.d_ad_impression a
                  left join dim.dim_geo_city_info b on a.ext_geo_id = b.geo_code
                  left join dim.dim_area c on cast(a.ext_geo_id as varchar) = c.geo_b_id
         where thisdate >= '2020-12-01'
           and thisdate <= '2020-12-31'
           and ext_order_id in (2865)
           and ext_adgroup_id not in (
                                      240604,
                                      240609,
                                      240614,
                                      240619,
                                      240624,
                                      240629,
                                      240634,
                                      240639,
                                      240644,
                                      240649,
                                      240654,
                                      240659,
                                      240664,
                                      240671,
                                      240676,
                                      240681,
                                      240686,
                                      240691,
                                      240696,
                                      240701,
                                      240902,
                                      240907,
                                      240912,
                                      240917,
                                      240922,
                                      240927,
                                      240932,
                                      240937,
                                      240947,
                                      240952,
                                      240957,
                                      240962,
                                      240967,
                                      240972
             )
         group by 1, 2
     ) t
where city in ('北京', '上海', '深圳', '广州')
group by 1, 2


select distinct ext_user_id
from dwd.d_ad_ftx_dp_track_log a
where a.ext_advertiser_id = 2003553
  and a.user_agent like '%Android 1%'

select *
from (
         select distinct ext_campaign_id
         from dwd.d_ad_impression
         where thisdate >= '2020-12-01'
           and thisdate <= '2020-12-31'
           and ext_order_id = 2865
     ) a
         left join a6rds.ad_fancy.ad_group b
                   on a.ext_adgroup_id = b.;


select a.city,
       a.user_id

--        case when a.pv <= 6 then a.pv else 7 end as pinci,
--        count(1)                                 as uv,
--        sum(a.pv)                                as pv,
--        count(b.user_id)                         as duli,
--        sum(b.pv)                                as dianji
from (
         select replace(case when city is null then c.area_name else b.city end, '市')            as city,
                if(ext_user_id is null or ext_user_id = '', concat(ip, user_agent), ext_user_id) as user_id,
                count(distinct ext_request_id)                                                   as pv
         from dwd.d_ad_impression a
                  left join dim.dim_geo_city_info b on a.ext_geo_id = b.geo_code
                  left join dim.dim_area c on cast(a.ext_geo_id as varchar) = c.geo_b_id
         where thisdate >= '2020-12-01'
           and thisdate <= '2020-12-31'
           and ext_order_id = 2865
           and ext_adgroup_id not in (
                                      240604,
                                      240609,
                                      240614,
                                      240619,
                                      240624,
                                      240629,
                                      240634,
                                      240639,
                                      240644,
                                      240649,
                                      240654,
                                      240659,
                                      240664,
                                      240671,
                                      240676,
                                      240681,
                                      240686,
                                      240691,
                                      240696,
                                      240701,
                                      240902,
                                      240907,
                                      240912,
                                      240917,
                                      240922,
                                      240927,
                                      240932,
                                      240937,
                                      240947,
                                      240952,
                                      240957,
                                      240962,
                                      240967,
                                      240972
             )
         group by 1, 2
     ) a
         left join
     (
         select replace(case when city is null then c.area_name else b.city end, '市')            as city,
                if(ext_user_id is null or ext_user_id = '', concat(ip, user_agent), ext_user_id) as user_id,
                count(distinct ext_request_id)                                                   as pv
         from dwd.d_ad_clicklog_day a
                  left join dim.dim_geo_city_info b on a.ext_geo_id = b.geo_code
                  left join dim.dim_area c on cast(a.ext_geo_id as varchar) = c.geo_b_id
         where thisdate >= '2020-12-01'
           and thisdate <= '2020-12-31'
           and ext_order_id = 2865
           and ignore_rule = 0
           and ext_adgroup_id not in (
                                      240604,
                                      240609,
                                      240614,
                                      240619,
                                      240624,
                                      240629,
                                      240634,
                                      240639,
                                      240644,
                                      240649,
                                      240654,
                                      240659,
                                      240664,
                                      240671,
                                      240676,
                                      240681,
                                      240686,
                                      240691,
                                      240696,
                                      240701,
                                      240902,
                                      240907,
                                      240912,
                                      240917,
                                      240922,
                                      240927,
                                      240932,
                                      240937,
                                      240947,
                                      240952,
                                      240957,
                                      240962,
                                      240967,
                                      240972
             )
         group by 1, 2
     ) b
     on a.user_id = b.user_id and a.city = b.city
where a.city in ('北京', '上海', '深圳', '广州')
  and a.pv = 1
  and b.pv > 1
group by 1, 2


select count(distinct ext_user_id)
from dwd.d_ad_impression
where thisdate >= '2021-01-18'
  and thisdate <= '2021-02-04'
  and ext_order_id = 3040


select *
from dwd.d_ad_clicklog_day
where thisdate >= '2020-12-01'
  and thisdate <= '2020-12-31'
  and ext_order_id
    = 2865
  and ext_request_id = 'f858f00d462a6e0eacefeb8a83350028_7ea4c381723c4068a86e3a802ff81815'
--   and ext_user_id = '718ba61b68635907'


select count(distinct ext_user_id)
from dwd.d_ad_impression
where ext_advertiser_id = 2003472
  and thisdate >= '2020-04-17'
  and thisdate <= '2020-12-13'


select count(distinct if(ext_user_id is null or ext_user_id = '', concat(ext_ip, user_agent), ext_user_id))
from dwd.d_ad_impression
where ext_advertiser_id = 2003472
  and (thisdate between '2020-04-17' and '2020-05-03'
    or thisdate between '2020-06-05' and '2020-06-14'
    or thisdate between '2020-09-03' and '2020-09-30'
    or thisdate between '2020-12-04' and '2020-12-13')


    presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where thisdate = '2021-02-28'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-02-28' and ua_id not in ('0', '-1') and uid_type in ('1', '2', '3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 20000000
" --output-format TSV > 1838__202103021733;"

presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where thisdate = '2021-02-28'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-02-28' and ua_id not in ('0', '-1') and uid_type in ('2') and user_id not like 'M%'
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 10000000
" --output-format TSV > linshi2;"



select hour, count (distinct ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast (hour as int) >=19
  and cast (hour as int) <=23
group by 1


select hour, pinci, count (distinct ext_user_id)
from (
    select hour, ext_user_id, count (distinct ext_request_id) pinci
    from dwd.d_ad_impression
    where thisdate = '2021-02-23'
    and ext_campaign_id = 46898
    and cast (hour as int) >=19
    and cast (hour as int) <=23
    group by 1, 2
    ) a
group by 1, 2

-- 帮忙拉一份AMO订单列表
-- 1. 包含字段 订单ID，订单名称，执行周期，下单金额，实结金额
-- 2. 过滤条件（以下条件为与关系）
--     - 订单的执行结束时间在2021-01-01 到 2021-02-28 区间
--     - 订单的状态为有效状态 a.status > 1 and a.status < 7
--     - 下单金额 > 10
--     - 实结金额为空或者为0


-- 2. 过滤条件（以下条件为与关系）
--     - 订单的执行结束时间在2021-01-01 到 2021-02-28 区间
--     - 订单的状态为有效状态 a.status > 1 and a.status < 7
--     - 下单金额 > 10
--     - 实结金额为空或者为0

    presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where thisdate = '2021-02-28'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-02-28' and ua_id not in ('0', '-1') and uid_type in ('3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 20000000
" --output-format TSV > linshi3;"



select a.ext_ad_id, click, ftxclick
from (
         select ext_ad_id, count(distinct ext_request_id) click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) a
         left join (
    select ext_ad_id, count(distinct ext_request_id) ftxclick
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (464770, 465313)
    group by 1
) b
                   on a.ext_ad_id = b.ext_ad_id


select a.*
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
     ) a
         left join (
    select ext_request_id
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (464770, 465313)
) b
                   on a.ext_request_id = b.ext_request_id
where b.ext_request_id is not null limit 100

select thisdate, ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 1, 2


select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate, count(*) as dsp_click, count(distinct ext_request_id) as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
         order by 1
     ) a
         left join
     (
         select thisdate, count(*) as ftx_click, count(distinct ext_request_id) as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
         order by 1
     ) b on a.thisdate = b.thisdate
order by 1


select m_app_version,
       ext_request_id,
       ext_time, time, to_unixtime(cast (replace(time, '_', ' ') as timestamp))-q_time as jg
from
    (
    select b.m_app_version, a.ext_request_id, a.ext_time, a.time,
    lag(to_unixtime(cast (replace(a.time, '_', ' ') as timestamp))) over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as q_time,
    row_number() over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as num
    from dwd.d_ad_clicklog_day a inner join dwd.d_ad_request b on a.ext_request_id=b.request_id
    where a.thisdate = '2021-03-02'
    and a.ext_ad_id in (464770, 465313)
    ) a
where num>1


select if(a.ext_request_id is not null, not_mozilla, -1)        as not_mozilla,
       sum(if(a.ext_request_id is not null, m_click, 0))        as m_click,
       sum(if(a.ext_request_id is not null, ok_click, 0))       as ok_click,
       sum(if(a.ext_request_id is not null, IqiyiApp_click, 0)) as IqiyiApp_click,
       sum(if(a.ext_request_id is not null, dsp_click, 0))      as dsp_click,
       sum(if(a.ext_request_id is not null, ftx_click, 0))      as ftx_click
from (
         select ext_request_id,
                max(if(strpos(user_agent, 'Mozilla') <> 0, 0, 1))  as not_mozilla,
                sum(if(strpos(user_agent, 'Mozilla') <> 0, 1, 0))  as m_click,
                sum(if(strpos(user_agent, 'okhttp') <> 0, 1, 0))   as ok_click,
                sum(if(strpos(user_agent, 'IqiyiApp') <> 0, 1, 0)) as IqiyiApp_click,
                sum(1)                                             as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) a
         full outer join
     (
         select ext_request_id, sum(1) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) b on a.ext_request_id = b.ext_request_id
group by 1

select thisdate,
       case
           when ext_vendor_id in (147, 118) then '韩剧tv'
           when ext_vendor_id in (27, 28, 57, 58) then '腾讯'
           when ext_vendor_id in (29, 30) then '爱奇艺'
           else cast(ext_vendor_id as varchar)
           end as vendor,
       count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 1, 2


select ext_ip, ip, count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 3 desc



select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate,
                case when length(ext_user_id) = 32 then 'android' when length(ext_user_id) = 36 then 'ios' end as name,
                count(*)                                                                                       as dsp_click,
                count(distinct ext_request_id)                                                                 as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1, 2
         order by 1, 2
     ) a
         left join
     (
         select thisdate,
                case when ext_mobile_platform = 2 then 'android' when ext_mobile_platform = 1 then 'ios' end as name,
                count(*)                                                                                     as ftx_click,
                count(distinct ext_request_id)                                                               as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1, 2
         order by 1, 2
     ) b on a.thisdate = b.thisdate and a.name = b.name
order by 1, 2


select a.hour, dsp_click, ftx_click
from (
         select split(split(time, ' ')[2], ':')[1] as hour,count(*) as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770
             , 465313)
         group by 1
     ) a
         left join
     (
         select split(split(timestamp, ' ')[2], ':')[1] as hour,count(*) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770
             , 465313)
         group by 1
     ) b on a.hour = b.hour
order by 1

select ext_ad_id, ext_vendor_id
from d_ad_impression
where thisdate = '2021-03-02'
  and ext_ad_id in (464760,
                    464761,
                    464762,
                    464763,
                    464764,
                    464765,
                    464766,
                    464767,
                    464768,
                    464769,
                    464770,
                    464771,
                    464772,
                    464773,
                    464774, 464792,
                    464775, 464791,
                    464776,
                    464777,
                    464778,
                    464779,
                    464780,
                    464781,
                    464784,
                    464785,
                    464786,
                    464787,
                    464811,
                    464812,
                    465207,
                    465208,
                    465313,
                    465314)
group by 1, 2

select a.*, b.click
from (
         select ext_ad_id, ext_slot_id, count(distinct ext_request_id)
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313, 465314)
         group by 1, 2
     ) a
         left join (
    select ext_ad_id, ext_slot_id, count(distinct ext_request_id) click
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313, 465314)
    group by 1, 2
) b
                   on a.ext_ad_id = b.ext_ad_id and a.ext_slot_id = b.ext_slot_id


select ext_vendor_id, ext_app_name
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (465313, 465314)
group by 1, 2


select m_app_version,
       ext_request_id,
       ext_time, time, to_unixtime(cast (replace(time, '_', ' ') as timestamp))-q_time as jg
from
    (
    select b.m_app_version, a.ext_request_id, a.ext_time, a.time,
    lag(to_unixtime(cast (replace(a.time, '_', ' ') as timestamp))) over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as q_time,
    row_number() over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as num
    from dwd.d_ad_clicklog_day a inner join dwd.d_ad_request b on a.ext_request_id=b.request_id
    where a.thisdate = '2021-03-02'
    and a.ext_ad_id in (464770, 464771)
    ) a
where num>1


select count(ext_request_id), count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 464771)


select *
from (select thisdate, ext_app_name, count(ext_request_id), count(distinct ext_request_id)
      from dwd.d_ad_impression
      where thisdate >= '2021-03-01'
        and thisdate <= '2021-03-02'
        and ext_app_name in ('weather.nd.com.iPhone',
                             'viva.reader',
                             'tv.yixia.bobo',
                             'com.zongyi.ndoudizhu',
                             'com.youhessp.zhangyu',
                             'com.wifi.reader.lite',
                             'com.wifi.quickapp.reader.free',
                             'com.wemomo.momoappdemo1',
                             'com.moxiu.launcher',
                             'com.mianfeizs.book',
                             'com.mianfeia.book',
                             'com.mfyueduqi.book',
                             'com.lechuan.midunovel',
                             'com.lechuan.mdwz',
                             'com.jxedt',
                             'com.ipeaksoft.keng16.mi',
                             'com.immomo.momo',
                             'com.iflytek.iFlySpeechPlus',
                             'com.icoolme.android.weather',
                             'com.gw.dzhiphone622',
                             'com.eonsun.myreader',
                             'com.cyjh.mobileanjian',
                             'com.chaozh.iReaderFree',
                             'com.carben.carben',
                             'com.calendar.UI',
                             'com.baidu.yuedu',
                             'com.android.dazhihui',
                             'changdumagazine1.0')
      group by 1, 2) a
         left join(
    select thisdate, ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate >= '2021-03-01'
      and thisdate <= '2021-03-02'
      and ext_app_name in ('weather.nd.com.iPhone',
                           'viva.reader',
                           'tv.yixia.bobo',
                           'com.zongyi.ndoudizhu',
                           'com.youhessp.zhangyu',
                           'com.wifi.reader.lite',
                           'com.wifi.quickapp.reader.free',
                           'com.wemomo.momoappdemo1',
                           'com.moxiu.launcher',
                           'com.mianfeizs.book',
                           'com.mianfeia.book',
                           'com.mfyueduqi.book',
                           'com.lechuan.midunovel',
                           'com.lechuan.mdwz',
                           'com.jxedt',
                           'com.ipeaksoft.keng16.mi',
                           'com.immomo.momo',
                           'com.iflytek.iFlySpeechPlus',
                           'com.icoolme.android.weather',
                           'com.gw.dzhiphone622',
                           'com.eonsun.myreader',
                           'com.cyjh.mobileanjian',
                           'com.chaozh.iReaderFree',
                           'com.carben.carben',
                           'com.calendar.UI',
                           'com.baidu.yuedu',
                           'com.android.dazhihui',
                           'changdumagazine1.0')
    group by 1, 2) b
                  on a.ext_app_name = b.ext_app_name and a.thisdate = b.thisdate 设备id，设备类型 1 安卓 2ios 3其他，mac 528C8E6CD4A3C6598999A0E9DF15AD32 写死，geoid，广告主id，ua id

select distinct ext_user_id,
from dwd.d_ad_impression
where thisdate >= '2020-03-06'
  and thisdate <= '2020-12-12'
  and ext_advertiser_id = 2003472


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
                    else 3 end  pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id) geoid
         from dwd.d_ad_impression
         where thisdate >= '2020-03-06'
           and thisdate <= '2020-12-12'
           and ext_advertiser_id = 2003472
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
     on a.geoid = d.geo_id limit 10

select *
from (
         select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313,
                             465314,
                             465321,
                             465322,
                             465323,
                             465324,
                             465264,
                             465265,
                             465266,
                             465267)
         group by 1
     ) a
         left join(
    select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313,
                        465314,
                        465321,
                        465322,
                        465323,
                        465324,
                        465264,
                        465265,
                        465266,
                        465267)
    group by 1
) b
                  on a.ext_app_name = b.ext_app_name



select distinct ext_app_name
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (465313,
                    465314,
                    465321,
                    465322,
                    465323,
                    465324,
                    465264,
                    465265,
                    465266,
                    465267)


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
                    else 3 end  pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id) geoid
         from dwd.d_ad_impression
         where thisdate >= '2020-03-06'
           and thisdate <= '2020-12-12'
           and ext_advertiser_id = 2003472
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
     on a.geoid = d.geo_id " --output-format TSV > 1840__202103031531;"



select hour, sum (if(user_agent like '%Android 1%', 1, 0)), count (ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1



select *
from (
         select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313,
                             465314,
                             465321,
                             465322,
                             465323,
                             465324,
                             465264,
                             465265,
                             465266,
                             465267)
         group by 1
     ) a
         left join(
    select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313,
                        465314,
                        465321,
                        465322,
                        465323,
                        465324,
                        465264,
                        465265,
                        465266,
                        465267)
    group by 1
) b
                  on a.ext_app_name = b.ext_app_name

select *
from (
         select ext_app_name, ext_app_id, count(ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_adgroup_id in
               (250733, 250734, 250735, 250736, 250779, 250780, 250784, 250785, 250786, 250787, 250777, 250778)
         group by 1, 2
     ) a
         left join (
    select ext_app_name, ext_app_id, count(ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_adgroup_id in
          (250733, 250734, 250735, 250736, 250779, 250780, 250784, 250785, 250786, 250787, 250777, 250778)
    group by 1, 2
) b
                   on a.ext_app_id = b.ext_app_id



select hour
--   , if(user_agent like '%Android 1%', 1, 0)
--   , count (if(length (ext_mobile_oaid)>10)>1, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_imei_md5 is null, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_oaid is null, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_oaid is null and ext_mobile_imei_md5 is null, ext_request_id, null))
        , count (ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1


select ext_user_id, ext_mobile_idfa, ext_mobile_oaid, ext_mobile_imei_md5
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast(hour as int) >= 19
  and cast(hour as int) <= 23 limit 10



select hour
        , case when user_agent like '%Android 1%' then '10'
    when user_agent like '%Android 9%' then '9'
    when user_agent like '%Android 8%' then '8'
    when user_agent like '%Android 7%' then '7'
    when user_agent like '%Android 6%' then '6'
    when user_agent like '%Android 5%' then '5'
    when user_agent like '%Android 4%' then '4'
end
,count (if(user_agent like '%Android%' and ext_mobile_imei_md5 is null, ext_request_id, null))
  ,count(ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1,2


-- 小时，安卓版本（分安卓10以下，安卓10以下两类即可
-- ），总曝光，（OAID，IMEI任意一个有值曝光数）
-- ，无IMEI曝光数，无OAID曝光数



select cast(hour as int)           "小时"
     , case
--            when user_agent like '%Android 1%' then '安卓10'
           when user_agent like '%Android%' then '安卓'
           else 'IOS' end          "安卓版本"
     , count(distinct ext_user_id) "总曝光设备"
--      , count(
--         if(length(ext_mobile_imei_md5) > 10 or length(ext_mobile_oaid) > 10, ext_request_id, null)) "OAID，IMEI任意一个有值曝光设备数"
--      , count( if(ext_mobile_imei_md5 is null, ext_request_id, null))                                 "无IMEI曝光设备数"
--      , count( if(ext_mobile_oaid is null, ext_request_id, null))                                 "无OAID曝光设备数"

from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast(hour as int) >= 19
  and cast(hour as int) <= 23
group by 1, 2


select *
from rpt.tmpimp__20210303 limit 1


select *
from dwd.d_ad_impression
where thisdate = '2021-03-01';


select geo_code, count(ext_request_id)
from (
         select *
         from dwd.d_ad_impression
         where thisdate = '2021-03-01'
           and ext_adgroup_id in (250682, 250484, 250448, 250446, 250444, 250681, 250479, 250447, 250445, 250443)
           and ext_vendor_id = 227
     ) a
         left join (
    select url_extract_parameter(concat('http://abc?', query_string), 'idfa') as t,
           remote_ip,
           useragent,
           *
    from rpt.tmpimp__20210303
) b on a.ext_user_id = b.t
where b.t is null
group by 1
;;;;;;



presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where thisdate = '2021-02-28'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-02-28' and ua_id not in ('0', '-1') and uid_type in ('2') and user_id not like 'M%'
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 10000000
" --output-format TSV > linshi2;"



select hour, count (distinct ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast (hour as int) >=19
  and cast (hour as int) <=23
group by 1


select hour, pinci, count (distinct ext_user_id)
from (
    select hour, ext_user_id, count (distinct ext_request_id) pinci
    from dwd.d_ad_impression
    where thisdate = '2021-02-23'
    and ext_campaign_id = 46898
    and cast (hour as int) >=19
    and cast (hour as int) <=23
    group by 1, 2
    ) a
group by 1, 2

-- 帮忙拉一份AMO订单列表
-- 1. 包含字段 订单ID，订单名称，执行周期，下单金额，实结金额
-- 2. 过滤条件（以下条件为与关系）
--     - 订单的执行结束时间在2021-01-01 到 2021-02-28 区间
--     - 订单的状态为有效状态 a.status > 1 and a.status < 7
--     - 下单金额 > 10
--     - 实结金额为空或者为0


-- 2. 过滤条件（以下条件为与关系）
--     - 订单的执行结束时间在2021-01-01 到 2021-02-28 区间
--     - 订单的状态为有效状态 a.status > 1 and a.status < 7
--     - 下单金额 > 10
--     - 实结金额为空或者为0

    presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where thisdate = '2021-02-28'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-02-28' and ua_id not in ('0', '-1') and uid_type in ('3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 20000000
" --output-format TSV > linshi3;"



select a.ext_ad_id, click, ftxclick
from (
         select ext_ad_id, count(distinct ext_request_id) click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) a
         left join (
    select ext_ad_id, count(distinct ext_request_id) ftxclick
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (464770, 465313)
    group by 1
) b
                   on a.ext_ad_id = b.ext_ad_id


select a.*
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
     ) a
         left join (
    select ext_request_id
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (464770, 465313)
) b
                   on a.ext_request_id = b.ext_request_id
where b.ext_request_id is not null limit 100

select thisdate, ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 1, 2


select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate, count(*) as dsp_click, count(distinct ext_request_id) as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
         order by 1
     ) a
         left join
     (
         select thisdate, count(*) as ftx_click, count(distinct ext_request_id) as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
         order by 1
     ) b on a.thisdate = b.thisdate
order by 1


select m_app_version,
       ext_request_id,
       ext_time, time, to_unixtime(cast (replace(time, '_', ' ') as timestamp))-q_time as jg
from
    (
    select b.m_app_version, a.ext_request_id, a.ext_time, a.time,
    lag(to_unixtime(cast (replace(a.time, '_', ' ') as timestamp))) over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as q_time,
    row_number() over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as num
    from dwd.d_ad_clicklog_day a inner join dwd.d_ad_request b on a.ext_request_id=b.request_id
    where a.thisdate = '2021-03-02'
    and a.ext_ad_id in (464770, 465313)
    ) a
where num>1


select if(a.ext_request_id is not null, not_mozilla, -1)        as not_mozilla,
       sum(if(a.ext_request_id is not null, m_click, 0))        as m_click,
       sum(if(a.ext_request_id is not null, ok_click, 0))       as ok_click,
       sum(if(a.ext_request_id is not null, IqiyiApp_click, 0)) as IqiyiApp_click,
       sum(if(a.ext_request_id is not null, dsp_click, 0))      as dsp_click,
       sum(if(a.ext_request_id is not null, ftx_click, 0))      as ftx_click
from (
         select ext_request_id,
                max(if(strpos(user_agent, 'Mozilla') <> 0, 0, 1))  as not_mozilla,
                sum(if(strpos(user_agent, 'Mozilla') <> 0, 1, 0))  as m_click,
                sum(if(strpos(user_agent, 'okhttp') <> 0, 1, 0))   as ok_click,
                sum(if(strpos(user_agent, 'IqiyiApp') <> 0, 1, 0)) as IqiyiApp_click,
                sum(1)                                             as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) a
         full outer join
     (
         select ext_request_id, sum(1) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1
     ) b on a.ext_request_id = b.ext_request_id
group by 1

select thisdate,
       case
           when ext_vendor_id in (147, 118) then '韩剧tv'
           when ext_vendor_id in (27, 28, 57, 58) then '腾讯'
           when ext_vendor_id in (29, 30) then '爱奇艺'
           else cast(ext_vendor_id as varchar)
           end as vendor,
       count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 1, 2


select ext_ip, ip, count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 465313)
group by 1, 2
order by 3 desc



select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate,
                case when length(ext_user_id) = 32 then 'android' when length(ext_user_id) = 36 then 'ios' end as name,
                count(*)                                                                                       as dsp_click,
                count(distinct ext_request_id)                                                                 as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1, 2
         order by 1, 2
     ) a
         left join
     (
         select thisdate,
                case when ext_mobile_platform = 2 then 'android' when ext_mobile_platform = 1 then 'ios' end as name,
                count(*)                                                                                     as ftx_click,
                count(distinct ext_request_id)                                                               as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770, 465313)
         group by 1, 2
         order by 1, 2
     ) b on a.thisdate = b.thisdate and a.name = b.name
order by 1, 2


select a.hour, dsp_click, ftx_click
from (
         select split(split(time, ' ')[2], ':')[1] as hour,count(*) as dsp_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770
             , 465313)
         group by 1
     ) a
         left join
     (
         select split(split(timestamp, ' ')[2], ':')[1] as hour,count(*) as ftx_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-02'
           and ext_ad_id in (464770
             , 465313)
         group by 1
     ) b on a.hour = b.hour
order by 1

select ext_ad_id, ext_vendor_id
from d_ad_impression
where thisdate = '2021-03-02'
  and ext_ad_id in (464760,
                    464761,
                    464762,
                    464763,
                    464764,
                    464765,
                    464766,
                    464767,
                    464768,
                    464769,
                    464770,
                    464771,
                    464772,
                    464773,
                    464774, 464792,
                    464775, 464791,
                    464776,
                    464777,
                    464778,
                    464779,
                    464780,
                    464781,
                    464784,
                    464785,
                    464786,
                    464787,
                    464811,
                    464812,
                    465207,
                    465208,
                    465313,
                    465314)
group by 1, 2

select a.*, b.click
from (
         select ext_ad_id, ext_slot_id, count(distinct ext_request_id)
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313, 465314)
         group by 1, 2
     ) a
         left join (
    select ext_ad_id, ext_slot_id, count(distinct ext_request_id) click
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313, 465314)
    group by 1, 2
) b
                   on a.ext_ad_id = b.ext_ad_id and a.ext_slot_id = b.ext_slot_id


select ext_vendor_id, ext_app_name
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (465313, 465314)
group by 1, 2


select m_app_version,
       ext_request_id,
       ext_time, time, to_unixtime(cast (replace(time, '_', ' ') as timestamp))-q_time as jg
from
    (
    select b.m_app_version, a.ext_request_id, a.ext_time, a.time,
    lag(to_unixtime(cast (replace(a.time, '_', ' ') as timestamp))) over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as q_time,
    row_number() over(partition by a.ext_request_id order by replace(a.time, '_', ' ')) as num
    from dwd.d_ad_clicklog_day a inner join dwd.d_ad_request b on a.ext_request_id=b.request_id
    where a.thisdate = '2021-03-02'
    and a.ext_ad_id in (464770, 464771)
    ) a
where num>1


select count(ext_request_id), count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (464770, 464771)


select *
from (select thisdate, ext_app_name, count(ext_request_id), count(distinct ext_request_id)
      from dwd.d_ad_impression
      where thisdate >= '2021-03-01'
        and thisdate <= '2021-03-02'
        and ext_app_name in ('weather.nd.com.iPhone',
                             'viva.reader',
                             'tv.yixia.bobo',
                             'com.zongyi.ndoudizhu',
                             'com.youhessp.zhangyu',
                             'com.wifi.reader.lite',
                             'com.wifi.quickapp.reader.free',
                             'com.wemomo.momoappdemo1',
                             'com.moxiu.launcher',
                             'com.mianfeizs.book',
                             'com.mianfeia.book',
                             'com.mfyueduqi.book',
                             'com.lechuan.midunovel',
                             'com.lechuan.mdwz',
                             'com.jxedt',
                             'com.ipeaksoft.keng16.mi',
                             'com.immomo.momo',
                             'com.iflytek.iFlySpeechPlus',
                             'com.icoolme.android.weather',
                             'com.gw.dzhiphone622',
                             'com.eonsun.myreader',
                             'com.cyjh.mobileanjian',
                             'com.chaozh.iReaderFree',
                             'com.carben.carben',
                             'com.calendar.UI',
                             'com.baidu.yuedu',
                             'com.android.dazhihui',
                             'changdumagazine1.0')
      group by 1, 2) a
         left join(
    select thisdate, ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate >= '2021-03-01'
      and thisdate <= '2021-03-02'
      and ext_app_name in ('weather.nd.com.iPhone',
                           'viva.reader',
                           'tv.yixia.bobo',
                           'com.zongyi.ndoudizhu',
                           'com.youhessp.zhangyu',
                           'com.wifi.reader.lite',
                           'com.wifi.quickapp.reader.free',
                           'com.wemomo.momoappdemo1',
                           'com.moxiu.launcher',
                           'com.mianfeizs.book',
                           'com.mianfeia.book',
                           'com.mfyueduqi.book',
                           'com.lechuan.midunovel',
                           'com.lechuan.mdwz',
                           'com.jxedt',
                           'com.ipeaksoft.keng16.mi',
                           'com.immomo.momo',
                           'com.iflytek.iFlySpeechPlus',
                           'com.icoolme.android.weather',
                           'com.gw.dzhiphone622',
                           'com.eonsun.myreader',
                           'com.cyjh.mobileanjian',
                           'com.chaozh.iReaderFree',
                           'com.carben.carben',
                           'com.calendar.UI',
                           'com.baidu.yuedu',
                           'com.android.dazhihui',
                           'changdumagazine1.0')
    group by 1, 2) b
                  on a.ext_app_name = b.ext_app_name and a.thisdate = b.thisdate 设备id，设备类型 1 安卓 2ios 3其他，mac 528C8E6CD4A3C6598999A0E9DF15AD32 写死，geoid，广告主id，ua id

select distinct ext_user_id,
from dwd.d_ad_impression
where thisdate >= '2020-03-06'
  and thisdate <= '2020-12-12'
  and ext_advertiser_id = 2003472


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
                    else 3 end  pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id) geoid
         from dwd.d_ad_impression
         where thisdate >= '2020-03-06'
           and thisdate <= '2020-12-12'
           and ext_advertiser_id = 2003472
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
     on a.geoid = d.geo_id limit 10

select *
from (
         select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313,
                             465314,
                             465321,
                             465322,
                             465323,
                             465324,
                             465264,
                             465265,
                             465266,
                             465267)
         group by 1
     ) a
         left join(
    select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313,
                        465314,
                        465321,
                        465322,
                        465323,
                        465324,
                        465264,
                        465265,
                        465266,
                        465267)
    group by 1
) b
                  on a.ext_app_name = b.ext_app_name



select distinct ext_app_name
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-02'
  and ext_ad_id in (465313,
                    465314,
                    465321,
                    465322,
                    465323,
                    465324,
                    465264,
                    465265,
                    465266,
                    465267)


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
                    else 3 end  pf
              , ext_device_type
              , ext_advertiser_id
              , ua_id_v2
              , ext_mobile_mac
              , max(ext_geo_id) geoid
         from dwd.d_ad_impression
         where thisdate >= '2020-03-06'
           and thisdate <= '2020-12-12'
           and ext_advertiser_id = 2003472
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
     on a.geoid = d.geo_id " --output-format TSV > 1840__202103031531;"



select hour, sum (if(user_agent like '%Android 1%', 1, 0)), count (ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1



select *
from (
         select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_ad_id in (465313,
                             465314,
                             465321,
                             465322,
                             465323,
                             465324,
                             465264,
                             465265,
                             465266,
                             465267)
         group by 1
     ) a
         left join(
    select ext_app_name, count(ext_request_id), count(distinct ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_ad_id in (465313,
                        465314,
                        465321,
                        465322,
                        465323,
                        465324,
                        465264,
                        465265,
                        465266,
                        465267)
    group by 1
) b
                  on a.ext_app_name = b.ext_app_name

select *
from (
         select ext_app_name, ext_app_id, count(ext_request_id)
         from dwd.d_ad_impression
         where thisdate = '2021-03-02'
           and ext_adgroup_id in
               (250733, 250734, 250735, 250736, 250779, 250780, 250784, 250785, 250786, 250787, 250777, 250778)
         group by 1, 2
     ) a
         left join (
    select ext_app_name, ext_app_id, count(ext_request_id)
    from dwd.d_ad_clicklog_day
    where thisdate = '2021-03-02'
      and ext_adgroup_id in
          (250733, 250734, 250735, 250736, 250779, 250780, 250784, 250785, 250786, 250787, 250777, 250778)
    group by 1, 2
) b
                   on a.ext_app_id = b.ext_app_id



select hour
--   , if(user_agent like '%Android 1%', 1, 0)
--   , count (if(length (ext_mobile_oaid)>10)>1, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_imei_md5 is null, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_oaid is null, ext_request_id, null))
        , count (if(user_agent like '%Android%' and ext_mobile_oaid is null and ext_mobile_imei_md5 is null, ext_request_id, null))
        , count (ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1


select ext_user_id, ext_mobile_idfa, ext_mobile_oaid, ext_mobile_imei_md5
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast(hour as int) >= 19
  and cast(hour as int) <= 23 limit 10



select hour
        , case when user_agent like '%Android 1%' then '10'
    when user_agent like '%Android 9%' then '9'
    when user_agent like '%Android 8%' then '8'
    when user_agent like '%Android 7%' then '7'
    when user_agent like '%Android 6%' then '6'
    when user_agent like '%Android 5%' then '5'
    when user_agent like '%Android 4%' then '4'
end
,count (if(user_agent like '%Android%' and ext_mobile_imei_md5 is null, ext_request_id, null))
  ,count(ext_request_id)
from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id=46898
  and cast (hour as int) >= 19
  and cast (hour as int) <=23
group by 1,2


-- 小时，安卓版本（分安卓10以下，安卓10以下两类即可
-- ），总曝光，（OAID，IMEI任意一个有值曝光数）
-- ，无IMEI曝光数，无OAID曝光数



select cast(hour as int)           "小时"
     , case
--            when user_agent like '%Android 1%' then '安卓10'
           when user_agent like '%Android%' then '安卓'
           else 'IOS' end          "安卓版本"
     , count(distinct ext_user_id) "总曝光设备"
--      , count(
--         if(length(ext_mobile_imei_md5) > 10 or length(ext_mobile_oaid) > 10, ext_request_id, null)) "OAID，IMEI任意一个有值曝光设备数"
--      , count( if(ext_mobile_imei_md5 is null, ext_request_id, null))                                 "无IMEI曝光设备数"
--      , count( if(ext_mobile_oaid is null, ext_request_id, null))                                 "无OAID曝光设备数"

from dwd.d_ad_impression
where thisdate = '2021-02-23'
  and ext_campaign_id = 46898
  and cast(hour as int) >= 19
  and cast(hour as int) <= 23
group by 1, 2


select *
from rpt.tmpimp__20210303 limit 1


select *
from dwd.d_ad_impression
where thisdate = '2021-03-01';


select geo_code, count(ext_request_id)
from (
         select *
         from dwd.d_ad_impression
         where thisdate = '2021-03-01'
           and ext_adgroup_id in (250682, 250484, 250448, 250446, 250444, 250681, 250479, 250447, 250445, 250443)
           and ext_vendor_id = 227
     ) a
         left join (
    select url_extract_parameter(concat('http://abc?', query_string), 'idfa') as t,
           remote_ip,
           useragent,
           *
    from rpt.tmpimp__20210303
) b on a.ext_user_id = b.t
where b.t is null
group by 1
;;;;;;



select geo_id, count(ext_request_id)
from (
         select *
         from dwd.d_ad_impression
         where thisdate = '2021-03-01'
           and ext_adgroup_id in (250682, 250484, 250448, 250446, 250444, 250681, 250479, 250447, 250445, 250443)
           and ext_vendor_id = 227
     ) a
         left join (
    select url_extract_parameter(concat('http://abc?', query_string), 'idfa') as t,
           remote_ip,
           useragent,
           *
    from rpt.tmpimp__20210303
) b on a.ext_user_id = b.t
where b.t is null
group by 1



select ext_user_id
from (
         select ext_user_id, count(distinct ext_request_id) pc
         from dwd.d_ad_impression
         where ext_adgroup_id in
               (250961, 250964, 250967, 250970, 250973, 250976, 250977, 250978, 250979, 250995, 250996, 250997, 250998,
                250999, 251000, 250938, 250939, 250940, 250960, 250963, 250966, 250969, 250972, 250975, 251033, 251034,
                251035)
           and thisdate >= '2021-03-04'
         group by 1
     ) a
where pc >= 2 limit 10;



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



select ext_request_id, ip, user_agent, timestamp
from dwd.d_ad_impression
where thisdate ='2021-02-25'
  and ext_adgroup_id in (249048
    , 249046)
  and ext_request_id in (
    '47cbbc3cb5a044189c5f35842bdbd8ff'
    , '4cd4b984ba9543799cdf7d06765059ff'
    , '6e1ea5058452408496ede90250f26cff'
    )
group by 1, 2, 3, 4

select ext_request_id, ip, user_agent, timestamp;


select count(*)
from dwd.d_ad_impression
where thisdate = '2021-02-25'
  and ext_adgroup_id in (249047, 249049, 249043, 249048,
                         249046)


select case
           when lower(name) like '%pre-roll%' or lower(name) like '%otv%' then 'Pre-roll'
           when lower(name) like '%feed%' then 'Feed'
           when lower(name) like '%banner%' then 'Banner'
           when lower(name) like '%ott%' then 'ott'
           when lower(name) like '%废弃%' then '废弃'
           else 'other'
           end
        ,
       case
           when lower(name) like '%boe%' then 'boe'
           when lower(name) like '%sustainable%' then 'Sus-Cloud'
           when lower(name) like '%cloud%' then 'Cloud'
           when lower(name) like '%security%' then 'Security'
           when lower(name) like '%cet%' then 'CX-Talent'
           when lower(name) like '%talent%' then 'Talent'
           when lower(name) like '%cec%' then 'CX-client'
           when lower(name) like '%client%' then 'client'


           else 'other'
           end
        ,
       count(distinct ext_user_id)
from dwd.d_ad_clicklog_day a
         left join u6rds.ad_fancy.ad_group b
                   on a.ext_adgroup_id = b.id
where thisdate >= '2020-12-01'
  and thisdate <= '2021-02-28'
  and ignore_rule = 0
  and ext_order_id in (2846, 2969, 2991)
group by 1, 2


select name
from dwd.d_ad_clicklog_day a
         left join u6rds.ad_fancy.ad_group b
                   on a.ext_adgroup_id = b.id
where thisdate >= '2020-12-01'
  and thisdate <= '2021-02-28'
  and ext_order_id in (2846, 2969, 2991)

  and lower(name) like '%cet%'
  and lower(name) like '%otv%'
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
         where ext_order_id = 3143
           and thisdate >= '2021-03-02'
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
    " --output-format TSV > 1849__202103081355;"


select count(ext_request_id)
from dwd.d_ad_clicklog_day
where ext_order_id = 3143
  and thisdate >= '2021-03-02'


select hour,
    count (ext_data_request_id)
from dspv2_imp_data
where thisdate = '2021-03-05'
  and ext_data_campaign_id = 809
group by 1

select substring(time, 11, 3), count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-09'
  and ext_ad_id = 465885
group by 1

select substring(time, 11, 3), ignore_rule, count(*) as click
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-09'
  and ext_ad_id = 465885
group by 1, 2
order by 1, 2


select a.t, if(user_agent like '%Android 1%', '安卓10', '其他'), count(a.ext_request_id), count(b.ext_request_id)
from (
         select substring(time, 11, 3) t, user_agent, ext_request_id
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
     ) a
         left join
     (
         select ext_request_id
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
     ) b on a.ext_request_id = b.ext_request_id
where b.ext_request_id is null
group by 1, 2
order by 1



select substring(time, 11, 3), if(a.user_agent like '%Android 1%', '安卓10', '其他'), count(a.ext_request_id)
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
     ) a
         left join (
    select *
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-09'
      and ext_ad_id = 465885
) b
                   on a.ext_request_id = b.ext_request_id
where b.ext_request_id is null
group by 1, 2


select thisdate,
       case
           when ext_vendor_id in (147, 118) then '韩剧tv'
           when ext_vendor_id in (27, 28, 57, 58) then '腾讯'
           when ext_vendor_id in (29, 30) then '爱奇艺'
           else cast(ext_vendor_id as varchar)
           end as vendor,
       count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-09'
  and ext_ad_id = 465885
group by 1, 2
order by 1, 2


select ext_ip, ip, count(distinct ext_request_id)
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-09'
  and ext_ad_id = 465885
group by 1, 2
order by 3 desc


select substring(time, 11, 3), a.ext_slot_id, count(a.ext_request_id)
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
     ) a
         left join (
    select *
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-09'
      and ext_ad_id = 465885
) b
                   on a.ext_request_id = b.ext_request_id
where b.ext_request_id is not null
  and a.ext_slot_id = '31ED286BC8C3FC6C090AE3E47D17ABEE'
group by 1, 2


select a.*, b.ftx_click, b.ftx_qc_click
from (
         select thisdate,
                case when length(ext_user_id) = 32 then 'android' when length(ext_user_id) = 36 then 'ios' end as name,
                count(*)                                                                                       as dsp_click,
                count(distinct ext_request_id)                                                                 as dsp_qc_click
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
         group by 1, 2
         order by 1, 2
     ) a
         left join
     (
         select thisdate,
                case when ext_mobile_platform = 2 then 'android' when ext_mobile_platform = 1 then 'ios' end as name,
                count(*)                                                                                     as ftx_click,
                count(distinct ext_request_id)                                                               as ftx_qc_click
         from dwd.d_ad_ftx_click_data
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
         group by 1, 2
         order by 1, 2
     ) b on a.thisdate = b.thisdate and a.name = b.name
order by 1, 2



select substring(time, 11, 3)
     , count(a.ext_request_id) fancy
     , count(b.ext_request_id) miaozhen
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate = '2021-03-09'
           and ext_ad_id = 465885
     ) a
         left join (
    select *
    from dwd.d_ad_ftx_click_data
    where thisdate = '2021-03-09'
      and ext_ad_id = 465885
) b
                   on a.ext_request_id = b.ext_request_id
where ext_app_name = 'com.klauncher.knews'
group by 1


select distinct ext_direct_deal_id
from dwd.d_ad_clicklog_day
where thisdate = '2021-03-09'
  and ext_ad_id = 465885
  and ext_app_name = 'com.klauncher.knews'

select a.thisdate, count(a.ext_request_id), count(b.ext_request_id)
from (
         select *
         from dwd.d_ad_clicklog_day
         where thisdate >= '2021-03-01'
           and ext_adgroup_id in
               (250594, 250595, 250596, 250597, 250598, 250599, 250600, 250601, 250602, 250603, 250604, 250605, 250606,
                250607, 250608, 250609, 250610, 250611, 250757, 250758, 250759, 250760, 250761, 250762, 250763, 250764,
                250765, 251070, 251071, 251072)
     ) a
         left join (
    select *
    from dwd.d_ad_ftx_click_data
    where thisdate >= '2021-03-01'
      and ext_dsp_adgroup_id in
          (250594, 250595, 250596, 250597, 250598, 250599, 250600, 250601, 250602, 250603, 250604, 250605, 250606,
           250607, 250608, 250609, 250610, 250611, 250757, 250758, 250759, 250760, 250761, 250762, 250763, 250764,
           250765, 251070, 251071, 251072)
) b on a.ext_request_id = b.ext_request_id
group by 1


select site_video_ids,
       count(1) cnt
from dwd.d_ad_ftx_request
where thisdate >= '2021-03-05'
  and thisdate <= '2021-03-05'
  and source_id = 118
  and mobile_app_name = 'bbcktv'
  and site_video_ids!=''
group by 1

select thisdate, mobile_app_name, source_id, site_video_ids
from dwd.d_ad_ftx_request
where thisdate = '2021-03-09'
  and mobile_app_name = 'bbcktv'
  and source_id = 118
  and site_video_ids = 'F4UgiKKJq8bUcy5Ll2v2' limit 1


select *
from (
         select ext_request_id
         from dwd.d_ad_impression
         where thisdate = '2021-03-09'
           and ext_order_id in (3095, 3145)
         group by 1
     ) a
         join (
    select id
    from dwd.d_ad_ftx_request
    where thisdate = '2021-03-09'
      and mobile_app_name = 'bbcktv'
      and source_id = 118
      and site_video_ids = 'F4UgiKKJq8bUcy5Ll2v2'
) b
              on a.ext_request_id = b.id limit 1

presto --execute "
with
    tag_sub as (
    select fancy_id from rpt.base_all_tags
    where source_id = '1' and thisdate = '2021-03-07'
    and (fancy_gender in ('2500100020'))
    )
        ,
    user_sub as (
    select user_id as uid, uid_type, mac, geo_code, '0' as advertiser_id, ua_id
    from rpt.base_device_ua_id_v2
    where thisdate = '2021-03-08' and ua_id not in ('0', '-1') and uid_type in ('1', '2', '3') and user_id not like 'M%'
    and ( geo_code like '1560%' )
    limit 200000000
    )
        ,
    ua_sub as (
    select distinct ua_id from u6rds.ad_fancy.base_ua_id_info
    )

select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type = '3'
union all
select user_sub.uid                       as user_id
     , user_sub.uid_type
     , '528C8E6CD4A3C6598999A0E9DF15AD32' as mac
     , user_sub.geo_code
     , user_sub.advertiser_id
     , user_sub.ua_id
from tag_sub
         join user_sub on tag_sub.fancy_id = user_sub.uid
         join ua_sub on user_sub.ua_id = ua_sub.ua_id
where uid_type in ('1', '2') limit 20000000
" --output-format TSV > 1;

select ext_app_name,
       count(a.ext_request_id),
       count(b.ext_request_id)
from (
         select *
         from dwd.d_ad_clicklog_day
         where ext_ad_id in (465919, 465984)
           and thisdate >= '2021-03-12'
--            and ext_slot_id = '31ED286BC8C3FC6C090AE3E47D17ABEE'
     ) a
         left join (
    select *
    from dwd.d_ad_ftx_click_data
    where ext_ad_id in (465919, 465984)
      and thisdate >= '2021-03-12'
--       and ext_slot_id = '31ED286BC8C3FC6C090AE3E47D17ABEE'
) b
                   on a.ext_request_id = b.ext_request_id
group by 1


select ext_direct_deal_id
from dwd.d_ad_clicklog_day
where ext_ad_id in (465919, 465984)
  and thisdate >= '2021-03-11'
  and ext_slot_id = '31ED286BC8C3FC6C090AE3E47D17ABEE'


select case
           when user_agent like '%IOS%' then ext_mobile_idfa
           when user_agent like '%Android 1%' then ext_mobile_oaid
           when user_agent like '%Android%' then ext_mobile_imei_md5
           else ext_user_id end

select ext_mobile_mac_md5 id
from dwd.d_ad_impression
where ext_adgroup_id in (240309, 240310, 240311, 240312, 240313, 240314, 240315, 240527)
  and thisdate >= '2020-12-01'
  and thisdate <= '2020-12-31'
group by 1


select vendor_id, name, count(DISTINCt user_id)
from rpt.base_device_member_orc a
         left join u6rds.dim.vendor b
                   on a.vendor_id = cast(b.id as varchar)
where thisdate <= '2021-03-14'

group by 1, 2



select case
           when c.name like '%腾讯%' then 'tx'
           when c.name like '%爱奇艺%' then 'aqy'
           when c.name like '%优酷%' then 'yk'
           when c.name like '%芒果%' then 'mg'
           else c.name end,
       approx_distinct(a.ext_user_id)
from (
         select *
         from dwd.d_ad_impression
         where thisdate <= '2021-03-17'
           and thisdate >= '2020-10-01'
           --tiepian 1 xinxiliu 8
           and ext_slot_type <> 1
     ) a
         left join(
    select *
    from dwd.d_ad_impression
    where thisdate <= '2021-03-17'
      and thisdate >= '2020-10-01'
      --tiepian 1 xinxiliu 8
      and ext_slot_type = 1
) b
                  on a.ext_user_id = b.ext_user_id and a.ext_vendor_id = b.ext_vendor_id
         join u6rds.dim.vendor c
              on a.ext_vendor_id = c.id
where b.ext_user_id is null
  and (c.name like '%腾讯%' or c.name like '%爱奇艺%' or c.name like '%优酷%' or c.name like '%芒果%')
group by 1



select c.name, count(distinct a.ftx_user_id)
from (
         select *
         from dwd.d_ad_ftx_request
         where thisdate = '2021-03-15'
           --tiepian 1 xinxiliu 8
           and ad_slot_type = 1
     ) a
         left join(
    select *
    from dwd.d_ad_ftx_request
    where thisdate = '2021-03-15'

      --tiepian 1 xinxiliu 8
      and d_ad_ftx_request.ad_slot_type <> 1
) b
                  on a.ftx_user_id = b.ftx_user_id and a.ftx_vendor_id = b.ftx_vendor_id
         join u6rds.dim.vendor c
              on a.ftx_vendor_id = c.id
where b.ftx_user_id is null
  and (c.name like '%腾讯%' or c.name like '%爱奇艺%' or c.name like '%优酷%' or c.name like '%芒果%')
group by 1



select vendor_id, count(*)
from dws.base_rtb_all_data_fancy_cate_orc a
         join u6rds.dim.vendor c
              on a.vendor_id = c.id
where op_day <= '2021-03-17'
  and op_day >= '2021-03-01'
  and (c.name like '%腾讯%' or c.name like '%爱奇艺%' or c.name like '%优酷%' or c.name like '%芒果%')
group by 1



select count(uid)
from (select vendor_id
           , upper(fancy_id)                                          as uid
           , sum(case when req_slot_type = 6 then 1 else 0 end)       as otv_pv
           , sum(case when req_slot_type in (1, 7) then 1 else 0 end) as not_otv_pv
      from dws.base_rtb_all_data_fancy_cate_orc
      where vendor_id in (27,
                          28,
                          57,
                          58,
                          73,
                          74,
                          171,
                          172,
                          188,
                          189,
                          247)
        and length(fancy_id) in (32, 36, 15, 16, 64)
        and is_mob = 1
        and op_day between '2021-03-14' and '2021-03-17'
      group by vendor_id, upper(fancy_id)) t
where t.otv_pv <= 1
  and t.not_otv_pv >= 7


select count(distinct ftx_user_id)
from (
         select ftx_user_id,
                sum(if(ad_slot_type = 1, 1, 0)) tp,
                sum(if(ad_slot_type = 1, 0, 1)) qt
         from dwd.d_ad_ftx_request
         where thisdate = '2021-03-17'
           and ftx_vendor_id in
--         腾讯
               (27, 28, 57, 58, 73, 74, 171, 172, 188, 189, 247, 10027, 10028, 10057, 10058, 10073, 10074, 10171, 10172,
                10188, 10189)
--          爱奇艺
--          (29,30,185,186,10029,10030,10185,10186)
--          优酷
--                 (47, 48, 149, 150, 10047, 10048, 10149, 10150)
--          芒果
--          (44,51,52,68,69,250,10044,10051,10052,10068,10069)
         group by 1
     ) a
where tp = 0
  and qt > 5



select
--        case
--            when lower(name) like '%banner%' then 'Banner'
--            when lower(name) like '%pre-roll%' or lower(name) like '%otv%' or lower(name) like '%贴片%' then 'Pre-roll'
--            when lower(name) like '%feed%' or lower(name) like '%信息流%' then 'Feed'
--            when lower(name) like '%废弃%' then '废弃'
--            else 'other'
--            end

    substring(thisdate, 6, 2)
     , case
           when lower(name) like '%dti%' then 'dti'
           when lower(name) like '%boe%' then 'boe'
           when lower(name) like '%sustainable%' then 'Sus-Cloud'
           when lower(name) like '%cloud%' then 'Cloud'
           when lower(name) like '%security%' then 'Security'
           when lower(name) like '%cet%' then 'CX-Talent'
           when lower(name) like '%talent%' then 'Talent'
           when lower(name) like '%cec%' then 'CX-client'
           when lower(name) like '%client%' then 'client'
           when lower(name) like '%ott%' then 'ott'
           else name
    end
     , count(distinct ext_request_id)
     , count(distinct ext_user_id)
from dwd.d_ad_clicklog_day a
         left join u6rds.ad_fancy.ad_group b
                   on a.ext_adgroup_id = b.id
where thisdate >= '2020-12-01'
  and thisdate <= '2021-02-28'
--   and ignore_rule = 0
  and ext_order_id in (2564, 2723, 2786, 2846, 2969, 2991)
--   and ext_adgroup_id not in
--       (226282, 226283, 226284, 226285, 226286, 226287, 226288, 226289, 226290, 226338, 226760, 226761, 226762, 226763,
--        228909)
group by 1,2


select count(distinct ext_user_id)
from dwd.d_ad_clicklog_day
where ext_adgroup_id not in
      (240309,245174,249037,240310,245175,249038,240311,245177,249039,240312,245178,249040,240313,245179,249041,240314,245181,249182,240315,245186,249183,240527,249184,249185)
  and thisdate >= '2020-09-01'
  and thisdate <= '2021-02-28'
and ext_order_id in (2564, 2723, 2786, 2846, 2969, 2991)
