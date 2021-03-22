-- 昨日消耗
select *
from (
         select date(table1.create_time)                                       "date",
                if(table1.vendor_id = 1, 1, 2)                                 "媒体",
                sum(cost) / 10000                                              "昨日总消耗",
                sum(case when create_channel = 1 then cost else 0 end) / 10000 "昨日api消耗"
         from makepolo.vendor_creative_report table1
                  left join makepolo.creative_report_dims table2
                            on table2.vendor_account_id = table1.vendor_account_id
                                and table2.vendor_creative_id = table1.vendor_creative_id
         where table1.create_time >= date_sub(curdate(), 2)
           and table1.create_time <= date_sub(curdate(), 1)
         group by 1, 2
         union
         select date(table1.create_time)                                       "date",
                0                                                              "媒体",
                sum(cost) / 10000                                              "昨日消耗",
                sum(case when create_channel = 1 then cost else 0 end) / 10000 "昨日api消耗"
         from makepolo.vendor_creative_report table1
                  left join makepolo.creative_report_dims table2
                            on table2.vendor_account_id = table1.vendor_account_id
                                and table2.vendor_creative_id = table1.vendor_creative_id
         where table1.create_time >= date_sub(curdate(), 2)
           and table1.create_time <= date_sub(curdate(), 1)
         group by 1, 2) tttttt
order by 媒体;

-- 昨日创建创意数
-- create_channel 1:api 0是媒体后台
select *
from (select dat
           , if(vendor_id = 1, 1, 2)                      "媒体"
           , sum(cnt_creative)                            "昨日总创建创意数"
           , sum(if(create_channel = 1, cnt_creative, 0)) "昨日api创建创意数"
      from makepolo.makepolo_creative_statistics
      where dat = date_sub(curdate(), 1)
      group by 1, 2
      union
      select dat
           , 0                                            "媒体"
           , sum(cnt_creative)                            "昨日总创建创意数"
           , sum(if(create_channel = 1, cnt_creative, 0)) "昨日api创建创意数"
      from makepolo.makepolo_creative_statistics
      where dat = date_sub(curdate(), 1)
      group by 1, 2) tttt
order by 媒体


-- 昨日新增客户
select c.type, ifnull(cou, 0) '昨日新增客户数'
from (select 1 type
      union
      select 2 type) c
         left join (
    select if(vendor_id = 1, 1, 2) type,
           count(distinct a.id)    cou
    from makepolo_common.account_admin a
             left join makepolo.entity_vendor_account b
                       on a.id = b.company_id
    where date(a.create_time) = date_sub(curdate(), 1)
    group by 1
) d
                   on c.type = d.type
order by 1
-- 昨日新绑定账户
select *
from (
         select date(create_time)
              , if(vendor_id = 1, 1, 2) "媒体"
              , count(distinct id) as   '昨日绑定账户数'
         from makepolo.entity_vendor_account
         where date(create_time) = date_sub(curdate(), interval 1 day)
         group by 1, 2
         union
         select date(create_time)
              , 0                     "媒体"
              , count(distinct id) as '昨日绑定账户数'
         from makepolo.entity_vendor_account
         where date(create_time) = date_sub(curdate(), interval 1 day)
         group by 1, 2) ttttt
order by 媒体

-- 昨日新增项目
select *
from (select if(b.vendor_id = 1, 1, 2) type, count(distinct a.id) as '昨日创建项目数'
      from makepolo.project a
               left join makepolo.entity_vendor_account b
                         on a.company_id = b.company_id
      where date(a.create_time) = date_sub(curdate(), interval 1 day)
      group by 1
      union
      select 0 type, count(distinct id) as '昨日创建项目数'
      from makepolo.project
      where date(create_time) = date_sub(curdate(), interval 1 day)) ttttt
order by 1

select *
from makepolo.project
where date(create_time) = date_sub(curdate(), interval 1 day)

-- 不活跃客户
select eva.company_id company_id
     , b.name
     , max(cr.create_time)
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = cr.vendor_account_id
         left join makepolo_common.account_admin b
                   on eva.company_id = b.id
where date(cr.create_time) <= curdate()
  and date(cr.create_time) >= date_sub(curdate(), 30)
group by 1, 2
having sum(case when create_channel = 1 then cost else 0 end) = 0
   and count(distinct eva.id) > 0
order by 3


-- api消耗top
select eva.company_id                                                 company_id
     , b.name                                                         company_name
     , sum(cost) / 10000                                              cost
     , sum(case when create_channel = 1 then cost else 0 end) / 10000 api_cost
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = cr.vendor_account_id
         left join makepolo_common.account_admin b
                   on eva.company_id = b.id
where cr.date = date_sub(curdate(), 1)
group by 1, 2
order by api_cost desc
limit 5

-- api创意创建top
select a.company_id
     , b.name
     , sum(cnt_creative)                            "昨日总创建创意数"
     , sum(if(create_channel = 1, cnt_creative, 0)) "昨日api创建创意数"
from makepolo.makepolo_creative_statistics a
         left join makepolo_common.account_admin b
                   on a.company_id = b.id
where dat = date_sub(curdate(), 1)
group by 1, 2
order by 4 desc
limit 5


-- 连续n天
select t1.id
     , t1.company_name
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where t1.id not in
      ( -- 近5天api创建创意0 有cost
          select e.company_id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
          group by 1
          having sum(if(d.date <= date_sub(curdate(), 1)
                            and d.date >= date_sub(curdate(), 8)
                            and e.create_channel = 1
              , cost, 0)) > 0)
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 8)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
   and sum(
               if(t2.dat = date_sub(curdate(), 7)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) >= 0
;

-- 连续n天
select t1.id           'Company ID'
     , t1.company_name '公司名称'
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where t1.id not in
      ( -- 排除所有有cost的账户
          select c.id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
                   join
               (
                   select a.id id
                   from makepolo_common.account_admin a
                            left join makepolo.makepolo_creative_statistics b
                                      on a.id = b.company_id
                        -- where b.dat <= curdate()
                        -- 连续n天，当前为1
                        --  and b.dat >= date_sub(curdate(), 7)
                        --  and b.create_channel = 1
                   group by 1
                   having sum(
                                  if(b.dat <= date_sub(curdate(), 1)
                                         and b.dat >= date_sub(curdate(), 8)
                                         and b.create_channel = 1
                                      , b.cnt_creative, 0)) = 0
               ) c
               on c.id = e.company_id
          where d.date <= date_sub(curdate(), 1)
            -- 连续n天，当前为7
            and d.date >= date_sub(curdate(), 8)
            and company_type = 0
          group by 1
          having sum(case when e.create_channel = 1 then cost else 0 end) > 0)
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 8)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
    join
(
    select a.id id
    from makepolo_common.account_admin a
             left join makepolo.makepolo_creative_statistics b
                       on a.id = b.company_id
         -- where b.dat <= curdate()
         -- 连续n天，当前为1
         --  and b.dat >= date_sub(curdate(), 7)
         --  and b.create_channel = 1
    group by 1
    having sum(
                   if(b.dat <= date_sub(curdate(), 1)
                          and b.dat >= date_sub(curdate(), 6)
                          and b.create_channel = 1
                       , b.cnt_creative, 0)) = 0
)
c
               on c.id = e.company_id



select t1.id
     , t1.company_name
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where -- t2.dat <= curdate()
      -- 连续n天，当前为1
      -- and t2.dat >= date_sub(curdate(), 7)
      -- and t2.create_channel = 1
      t1.id not in
      ( -- 排除所有有cost的账户，且创建创意数=0
          select c.id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
                   join
               (
                   select a.id id
                   from makepolo_common.account_admin a
                            left join makepolo.makepolo_creative_statistics b
                                      on a.id = b.company_id
                        -- where b.dat <= curdate()
                        -- 连续n天，当前为1
                        --  and b.dat >= date_sub(curdate(), 7)
                        --  and b.create_channel = 1
                   group by 1
                   having sum(
                                  if(b.dat <= date_sub(curdate(), 1)
                                         and b.dat >= date_sub(curdate(), 4)
                                         and b.create_channel = 1
                                      , b.cnt_creative, 0)) = 0
               ) c
               on c.id = e.company_id
          where d.date <= date_sub(curdate(), 1)
            -- 连续n天，当前为7
            and d.date >= date_sub(curdate(), 4)
          group by 1
          having sum(case when e.create_channel = 1 then cost else 0 end) > 0)
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 4)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
   and sum(
               if(t2.dat = date_sub(curdate(), 5)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) > 0


-- KA用户
select 'KA用户'                                                               as '用户种类'
     , count(a.company_id)                                                  as '客户数量'
     , round(sum(ctv_cnt_api), 2)                                           as 'api创建创意数'
     , round(sum(api_cost), 2)                                              as 'api消耗'
     , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost), 2)  as 'api消耗(环比)'
     , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api), 2) as 'api创建创意数(环比)'
     , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv), 2)             as '创建创意数(环比)'
from (
         select company_id
              , concat(max(b.name), ' ', max(b.id))                                      as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt, 0))     as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt_api, 0)) as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt, 0))     as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt_api, 0)) as last_ctv_api
         from rpt_fancy.mkpl_creative a
                  left join makepolo_common.account_admin b
                            on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 2 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
           and b.company_type <> 1
         group by 1
     ) a
         left join (
    select eva.company_id    as company_id
         , sum(cost) / 10000 as cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) /
           10000             as api_cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) /
           10000             as last_api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date >= date_sub(curdate(), interval 2 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
where api_cost > 50000
union all
-- 中级用户
select '中级用户'                                                               as '用户种类'
     , count(a.company_id)                                                  as '客户数量'
     , round(sum(ctv_cnt_api), 2)                                           as 'api创建创意数'
     , round(sum(api_cost), 2)                                              as 'api消耗'
     , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost), 2)  as 'api消耗(环比)'
     , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api), 2) as 'api创建创意数(环比)'
     , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv), 2)             as '创建创意数(环比)'
from (
         select company_id
              , concat(max(b.name), ' ', max(b.id))                                      as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt, 0))     as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt_api, 0)) as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt, 0))     as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt_api, 0)) as last_ctv_api
         from rpt_fancy.mkpl_creative a
                  left join makepolo_common.account_admin b
                            on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 2 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
           and b.company_type <> 1
         group by 1
     ) a
         left join (
    select eva.company_id    as company_id
         , sum(cost) / 10000 as cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) /
           10000             as api_cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) /
           10000             as last_api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date >= date_sub(curdate(), interval 2 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
where api_cost > 10000
  and api_cost < 50000
union all
-- 长尾用户
select '长尾用户'                                                               as '用户种类'
     , count(a.company_id)                                                  as '客户数量'
     , round(sum(ctv_cnt_api), 2)                                           as 'api创建创意数'
     , round(sum(api_cost), 2)                                              as 'api消耗'
     , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost), 2)  as 'api消耗(环比)'
     , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api), 2) as 'api创建创意数(环比)'
     , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv), 2)             as '创建创意数(环比)'
from (
         select company_id
              , concat(max(b.name), ' ', max(b.id))                                      as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt, 0))     as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt_api, 0)) as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt, 0))     as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt_api, 0)) as last_ctv_api
         from rpt_fancy.mkpl_creative a
                  left join makepolo_common.account_admin b
                            on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 2 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
           and b.company_type <> 1
         group by 1
     ) a
         left join (
    select eva.company_id    as company_id
         , sum(cost) / 10000 as cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) /
           10000             as api_cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) /
           10000             as last_api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date >= date_sub(curdate(), interval 2 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
where api_cost < 10000


# 新用户

select eva.company_id company_id
     , b.name
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = cr.vendor_account_id
         left join makepolo_common.account_admin b
                   on eva.company_id = b.id
where date(b.create_time) <= date_sub(curdate(), 1)
  and date(b.create_time) >= date_sub(curdate(), 8)
group by 1, 2
having sum(case when create_channel = 1 then cost else 0 end) > 0


select *
from makepolo_common.account_admin
limit 1
-- 无消耗用户
select eva.company_id company_id
     , b.name
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = cr.vendor_account_id
         left join makepolo_common.account_admin b
                   on eva.company_id = b.id
where date(b.create_time) <= date_sub(curdate(), 1)
  and date(b.create_time) >= date_sub(curdate(), 8)
group by 1, 2
having sum(case when create_channel = 1 then cost else 0 end) = 0

select row_number() over (order by 昨日api消耗 desc) Rank
        , ttt.*
from (
    select eva.company_id 'ID'
        , max(b.name) '代理商'
        , sum(cost) div 10000 '昨日总消耗'
        , sum(case when create_channel = 1 then cost else 0 end) div 10000 '昨日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 1)
    group by 1) ttt
limit 30

select row_number over (order by 昨日api创建创意数 desc)
     , ttt.*
from (select a.company_id                                 'ID'
           , b.name                                       '代理商'
           , sum(cnt_creative)                            "昨日总创建创意数"
           , sum(if(create_channel = 1, cnt_creative, 0)) "昨日api创建创意数"
      from makepolo.makepolo_creative_statistics a
               left join makepolo_common.account_admin b
                         on a.company_id = b.id
      where dat = date_sub(curdate(), 1)
      group by 1, 2) ttt
limit 30

select a.company_id
     , a.name           as '代理商名称'
     , cnt_creative     as "昨日总创建创意数"
     , api_cnt_creative as "昨日api创建创意数"
     , api_cost         as '昨日api消耗'
from (
         select a.company_id
              , b.name
              , sum(cnt_creative)                            as cnt_creative
              , sum(if(create_channel = 1, cnt_creative, 0)) as api_cnt_creative
         from makepolo.makepolo_creative_statistics a
                  left join makepolo_common.account_admin b
                            on a.company_id = b.id
         where dat = date_sub(curdate(), 1)
           and company_type = 0
         group by 1, 2
         order by 4 desc
         limit 5
     ) a
         left join (
    select eva.company_id as company_id
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) /
           10000          as api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date = date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
-- --------------------------------------------------------------------------------------------------------

select count(distinct id) as '昨日新增客户数'
from makepolo_common.account_admin
where company_type = 1
  and supervisor_company = 0
  and date(create_time) = date_sub(curdate(), interval 1 day)

select count(distinct b.id) as '昨日绑定账户数'
from makepolo.entity_vendor_account b -- 账户表
where date(b.create_time) = date_sub(curdate(), interval 1 day)

select count(distinct b.id) as '昨日创建项目数'
from makepolo.project b
where date(b.create_time) = date_sub(curdate(), interval 1 day)


-- 查询company_id = 51的昨日消耗
select eva.company_id                                          as company_id
     , sum(cost)                                               as cost
     , sum(case when create_channel = 1 then cost else 0 end)  as api_cost
     , sum(case when create_channel <> 1 then cost else 0 end) as kuaishou_cost
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
                       and dims.company_id in (51) -- 关联时筛选提高性能
         left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
where cr.date = date_sub(curdate(), interval 1 day)
  and eva.company_id in (51) -- 筛选company_id = 51
group by 1

select *
from makepolo.vendor_creative_report d
         left join makepolo.creative_report_dims e
                   on d.vendor_account_id = e.vendor_account_id
                       and d.vendor_creative_id = e.vendor_creative_id
limit 4



select t1.id           "Company ID"
     , t1.company_name "公司名称"
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where t1.id not in
      ( -- 排除所有有cost的账户，且创建创意数=0
          select c.id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
                   join
               (
                   select a.id id
                   from makepolo_common.account_admin a
                            left join makepolo.makepolo_creative_statistics b
                                      on a.id = b.company_id
                   group by 1
                   having sum(
                                  if(b.dat <= date_sub(curdate(), 1)
                                         and b.dat >= date_sub(curdate(), 4)
                                         and b.create_channel = 1
                                      , b.cnt_creative, 0)) = 0
               ) c
               on c.id = e.company_id
          where d.date <= date_sub(curdate(), 1)
            and d.date >= date_sub(curdate(), 8)
            and company_type = 0
          group by 1
          having sum(case when e.create_channel = 1 then cost else 0 end) > 0)
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 8)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
   and sum(
               if(t2.dat = date_sub(curdate(), 9)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) > 0



select t1.id
     , t1.company_name
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where t1.id not in
      ( -- 近5天api创建创意0 有cost
          select e.company_id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
          group by 1
          having sum(if(d.date <= date_sub(curdate(), 1)
                            and d.date >= date_sub(curdate(), 8)
                            and e.create_channel = 1
              , cost, 0)) > 0)
  and company_type = 0
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 8)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
   and sum(
               if(t2.dat = date_sub(curdate(), 9)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) > 0



select eva.company_id 'Company ID'
     , b.name         '公司名称'
from makepolo.vendor_creative_report cr
         left join makepolo.creative_report_dims dims
                   on dims.vendor_account_id = cr.vendor_account_id
                       and dims.vendor_creative_id = cr.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = cr.vendor_account_id
         left join makepolo_common.account_admin b
                   on eva.company_id = b.id
where date(b.create_time) <= date_sub(curdate(), 1)
  and date(b.create_time) >= date_sub(curdate(), 8)
  and company_type = 0
group by 1, 2
having sum(case when create_channel = 1 then cost else 0 end) > 0



select t1.id
     , t1.company_name
from makepolo_common.account_admin t1
         left join makepolo.makepolo_creative_statistics t2
                   on t1.id = t2.company_id
where t1.id not in
      ( -- 近5天api创建创意0 有cost
          select e.company_id
          from makepolo.vendor_creative_report d
                   left join makepolo.creative_report_dims e
                             on d.vendor_account_id = e.vendor_account_id
                                 and d.vendor_creative_id = e.vendor_creative_id
          where d.date <= date_sub(curdate(), 1)
            and d.date >= date_sub(curdate(), 8)
          group by 1
          having sum(if(e.create_channel = 1, cost, 0)) > 0)
  and company_type = 0
group by 1, 2
having sum(
               if(t2.dat <= date_sub(curdate(), 1)
                      and t2.dat >= date_sub(curdate(), 8)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) = 0
   and sum(
               if(t2.dat = date_sub(curdate(), 9)
                      and t2.create_channel = 1
                   , t2.cnt_creative, 0)) > 0



select id 'ID', name '代理商'
from makepolo_common.account_admin
where date(create_time) <= date_sub(curdate(), 1)
  and date(create_time) >= date_sub(curdate(), 8)
  and company_type = 0
group by 1, 2

-- 绑定账户新用户
select a.id 'ID', a.name '代理商'
from makepolo.entity_vendor_account b
         left join makepolo_common.account_admin a on b.company_id = a.id
where date(b.create_time) >= date_sub(curdate(), 8)
  and date(b.create_time) <= date_sub(curdate(), 1)
  and company_type = 0
group by 1, 2
having count(distinct b.id) > 0



select row_number() over (order by 昨日api创建创意数 desc) Rank
        , ID
        , `代理商名称`
        , `昨日总创建创意数`
        , `昨日api创建创意数`
        , split_part(money_format(`昨日api消耗`), '.', 1) as '昨日api消耗'
from (
    select a.company_id 'ID'
        , a.name as '代理商名称'
        , cnt_creative as "昨日总创建创意数"
        , api_cnt_creative as "昨日api创建创意数"
        , api_cost as '昨日api消耗'
    from
    (
    select a.company_id
        , b.name
        , split_part(money_format(sum(cnt_creative)), '.', 1) as cnt_creative
        , split_part(money_format(sum(if (create_channel = 1, cnt_creative, 0))), '.', 1) as api_cnt_creative
    from makepolo.makepolo_creative_statistics a
    left join makepolo_common.account_admin b
    on a.company_id = b.id
    where dat = date_sub(curdate(), 1) and company_type = 0
    and b.status = 1
    group by 1, 2
    order by 4 desc
    limit 5
    ) a
    left join (
    select eva.company_id as company_id
        , split_part(money_format(sum(case when create_channel=1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) div 10000), '.', 1) as api_cost
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva on eva.id=cr.vendor_account_id
    where date = date_sub(curdate(), interval 1 day)
    group by 1
    ) c
    on c.company_id = a.company_id
    order by 4 desc
    limit 5
    ) table1


select table1.ID                                                                                  'ID'
     , table1.代理商                                                                                 '代理商'
     , split_part(money_format(api_cost), '.', 1)                                                 '昨日api消耗'
     , split_part(money_format(yda_api_cost), '.', 1)                                             '前日api消耗'
     , concat(round(ifnull((api_cost - yda_api_cost) / yda_api_cost * 100, 0), 2), '%%')          'api消耗环比变化'
     , split_part(money_format(ks_api_cost), '.', 1)                                              '昨日快手api消耗'
     , split_part(money_format(ks_yda_api_cost), '.', 1)                                          '前日快手api消耗'
     , concat(round(ifnull((ks_api_cost - ks_yda_api_cost) / ks_yda_api_cost * 100, 0), 2), '%%') 'api快手消耗环比变化'
     , split_part(money_format(tt_api_cost), '.', 1)                                              '昨日头条api消耗'
     , split_part(money_format(tt_yda_api_cost), '.', 1)                                          '前日头条api消耗'
     , concat(round(ifnull((tt_api_cost - tt_yda_api_cost) / tt_yda_api_cost * 100, 0), 2), '%%') 'api头条消耗环比变化'

from (
         select eva.company_id 'ID'
              , a.company_name '代理商'
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost
                        else 0 end) div
                10000 as       api_cost
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost
                        else 0 end) div
                10000 as       yda_api_cost
         from makepolo.vendor_creative_report cr
                  left join makepolo.creative_report_dims dims
                            on dims.vendor_account_id = cr.vendor_account_id
                                and dims.vendor_creative_id = cr.vendor_creative_id
                  left join makepolo.entity_vendor_account eva
                            on eva.id = cr.vendor_account_id
                  left join makepolo_common.account_admin a
                            on a.id = eva.company_id
         where date <= date_sub(curdate(), interval 1 day)
           and date >= date_sub(curdate(), interval 2 day)
         group by 1, 2
     ) table1
         left join
     (
         select eva.company_id 'ID'
              , a.company_name '代理商'
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 1 day) and
                             cr.vendor_id = 1
                            then cost
                        else 0 end) div
                10000 as       ks_api_cost
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 2 day) and
                             cr.vendor_id = 1
                            then cost
                        else 0 end) div
                10000 as       ks_yda_api_cost
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 1 day) and
                             cr.vendor_id = 2
                            then cost
                        else 0 end) div
                10000 as       tt_api_cost
              , sum(case
                        when create_channel = 1 and date = date_sub(curdate(), interval 2 day) and
                             cr.vendor_id = 2
                            then cost
                        else 0 end) div
                10000 as       tt_yda_api_cost
         from makepolo.vendor_creative_report cr
                  left join makepolo.creative_report_dims dims
                            on dims.vendor_account_id = cr.vendor_account_id
                                and dims.vendor_creative_id = cr.vendor_creative_id
                  left join makepolo.entity_vendor_account eva
                            on eva.id = cr.vendor_account_id
                  left join makepolo_common.account_admin a
                            on a.id = eva.company_id
         where date <= date_sub(curdate(), interval 1 day)
           and date >= date_sub(curdate(), interval 2 day)
         group by 1, 2
     ) table2
     on table1.ID = table2.ID
where api_cost > 50000


select *
from makepolo.creative_report
limit 1

select row_number() over (order by a.昨日api消耗 desc) Rank
        , a.`ID`, a.`代理商`
        , split_part(money_format(a.昨日总消耗), '.', 1) as '昨日总消耗'
        , split_part(money_format(a.昨日api消耗), '.', 1) as '昨日api消耗'
        , concat(round((昨日api消耗-前日api消耗) / 前日api消耗 * 100,2),'%%') 'api消耗日环比变化'
        , concat(round((昨日api消耗-8日api消耗) / 8日api消耗 * 100,2),'%%') 'api消耗周同比变化'
from (
    select eva.company_id 'ID'
        , max(b.name) '代理商'
        , sum(cost) div 10000 '昨日总消耗'
        , sum(case when create_channel = 1 then cost else 0 end) div 10000 '昨日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 1) and company_type = 0
    and b.status = 1
    group by 1) a
    left join (
    select eva.company_id 'ID'
        , max(b.name) '代理商'
        , sum(case when create_channel = 1 then cost else 0 end) div 10000 '前日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 2) and company_type = 0
    and b.status = 1
    group by 1) b
on a.ID=b.ID
    left join (
    select eva.company_id 'ID'
    , max(b.name) '代理商'
    , sum(case when create_channel = 1 then cost else 0 end) div 10000 '8日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 8) and company_type = 0
    and b.status = 1
    group by 1) c
    on a.ID=c.ID
limit 5


select row_number() over (order by 昨日api创建创意数 desc) Rank
        , a.ID 'ID'
        , 代理商
        , split_part(money_format(昨日总创建创意数), '.', 1) '昨日总创建创意数'
        , split_part(money_format(昨日api创建创意数), '.', 1) '昨日总创建创意数'
        , split_part(money_format(昨日api消耗), '.', 1) as '昨日api消耗'
        , concat(round((昨日api消耗-前日api消耗) / 前日api消耗 * 100,2),'%%') 'api消耗日环比变化'
        , concat(round((昨日api消耗-8日api消耗) / 8日api消耗 * 100,2),'%%') 'api消耗周同比变化'
from
    (
    select a.company_id 'ID'
        , b.name '代理商'
        , sum(cnt_creative) as '昨日总创建创意数'
        , sum(if (create_channel = 1, cnt_creative, 0)) as '昨日api创建创意数'
    from makepolo.makepolo_creative_statistics a
    left join makepolo_common.account_admin b
    on a.company_id = b.id
    where dat = date_sub(curdate(), 1) and company_type = 0
    and b.status = 1
    group by 1, 2
    order by 4 desc
    limit 5
    ) a
    left join (
    select eva.company_id as 'ID'
        , sum(case when create_channel=1 then cost else 0 end) div 10000 as '昨日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva on eva.id=cr.vendor_account_id
    where date = date_sub(curdate(), interval 1 day)
    group by 1
    ) b
on b.ID = a.ID
    left join (
    select eva.company_id 'ID'
    , sum(case when create_channel = 1 then cost else 0 end) div 10000 '前日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 2) and company_type = 0
    and b.status = 1
    group by 1) d
    on a.ID=d.ID
    left join (
    select eva.company_id 'ID'
    , sum(case when create_channel = 1 then cost else 0 end) div 10000 '8日api消耗'
    from makepolo.vendor_creative_report cr
    left join makepolo.creative_report_dims dims
    on dims.vendor_account_id = cr.vendor_account_id
    and dims.vendor_creative_id = cr.vendor_creative_id
    left join makepolo.entity_vendor_account eva
    on eva.id = cr.vendor_account_id
    left join makepolo_common.account_admin b
    on eva.company_id = b.id
    where cr.date = date_sub(curdate(), 8) and company_type = 0
    and b.status = 1
    group by 1) c
    on a.ID=c.ID


select a.ID
     , a.代理商
     , if(b.flag = 1, '是', '否') '是否绑定账户'
     , if(c.flag = 1, '是', '否') '是否有api消耗'
     , if(d.flag = 1, '是', '否') '是否有api创建创意'
from (
         select id 'ID', name '代理商'
         from makepolo_common.account_admin
         where date(create_time) <= date_sub(curdate(), 1)
           and date(create_time) >= date_sub(curdate(), 8)
           and company_type = 0
           and status = 1
         group by 1, 2
     ) a
         left join (
    select ad.id 'ID', 1 flag
    from makepolo.entity_vendor_account vn
             left join makepolo_common.account_admin ad on vn.company_id = ad.id
    where date(ad.create_time) >= date_sub(curdate(), 8)
      and date(ad.create_time) <= date_sub(curdate(), 1)
      and company_type = 0
      and ad.status = 1
    group by 1, 2
    having count(distinct vn.id) > 0
) b
                   on a.ID = b.ID
         left join (
    select eva.company_id 'ID', 1 flag
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva
                       on eva.id = cr.vendor_account_id
             left join makepolo_common.account_admin b
                       on eva.company_id = b.id
    where date(b.create_time) <= date_sub(curdate(), 1)
      and date(b.create_time) >= date_sub(curdate(), 8)
      and company_type = 0
      and b.status = 1
    group by 1, 2
    having sum(case when create_channel = 1 then cost else 0 end) > 0
) c
                   on a.ID = c.ID
         left join (
    select ad.id "ID",
           1     flag
    from makepolo.makepolo_creative_statistics st
             left join makepolo_common.account_admin ad
                       on st.company_id = ad.id
    where date(ad.create_time) >= date_sub(curdate(), 8)
      and date(ad.create_time) <= date_sub(curdate(), 1)
      and company_type = 0
      and status = 1
    group by 1, 2
    having sum(if(create_channel = 1, cnt_creative, 0)) > 0
) d
                   on a.ID = d.ID



select a.id                                                               'ID'
     , a.name                                                             '代理商'
     , count(e.id)                                                        '绑定账户数'
     , sum(cost) div 10000                                                "总消耗"
     , sum(case when c.create_channel = 1 then cost else 0 end) div 10000 "api总消耗"
from makepolo_common.account_admin a
         left join makepolo.makepolo_creative_statistics b
                   on a.id = b.company_id
         left join makepolo.creative_report_dims c
                   on a.id = c.company_id
         left join makepolo.vendor_creative_report d
                   on c.vendor_account_id = d.vendor_account_id
                       and c.vendor_creative_id = d.vendor_creative_id
         left join makepolo.entity_vendor_account e
                   on a.id = e.company_id
where a.id in (
    select t1.id
    from makepolo_common.account_admin t1
             left join makepolo.makepolo_creative_statistics t2
                       on t1.id = t2.company_id
    where t1.id not in
          ( -- 近5天api创建创意0 有cost
              select e.company_id
              from makepolo.vendor_creative_report d
                       left join makepolo.creative_report_dims e
                                 on d.vendor_account_id = e.vendor_account_id
                                     and d.vendor_creative_id = e.vendor_creative_id
              where d.date <= date_sub(curdate(), 1)
                and d.date >= date_sub(curdate(), 8)
              group by 1
              having sum(if(e.create_channel = 1, cost, 0)) > 0)
      and company_type = 0
      and status = 1
      and date(t1.create_time) < date_sub(curdate(), 8)
      and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
    group by 1
    having sum(
                   if(t2.dat <= date_sub(curdate(), 1)
                          and t2.dat >= date_sub(curdate(), 8)
                          and t2.create_channel = 1
                       , t2.cnt_creative, 0)) = 0
)
group by 1, 2



select table1.ID
     , table1.代理商
     , table2.绑定账户数
     , split_part(money_format(总消耗), '.', 1)       '总消耗'
     , split_part(money_format(api总消耗), '.', 1)    'api总消耗'
     , split_part(money_format(总创建创意数), '.', 1)    '总创建创意数'
     , split_part(money_format(api总创建创意数), '.', 1) 'api总创建创意数'
from (
         select t1.id           'ID'
              , t1.company_name '代理商'
         from makepolo_common.account_admin t1
                  left join makepolo.makepolo_creative_statistics t2
                            on t1.id = t2.company_id
         where t1.id not in
               ( -- 近5天api创建创意0 有cost
                   select e.company_id
                   from makepolo.vendor_creative_report d
                            left join makepolo.creative_report_dims e
                                      on d.vendor_account_id = e.vendor_account_id
                                          and d.vendor_creative_id = e.vendor_creative_id
                   where d.date <= date_sub(curdate(), 1)
                     and d.date >= date_sub(curdate(), 8)
                   group by 1
                   having sum(if(e.create_channel = 1, cost, 0)) > 0)
           and company_type = 0
           and status = 1
           and date(t1.create_time) < date_sub(curdate(), 8)
           and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
         group by 1, 2
         having sum(
                        if(t2.dat <= date_sub(curdate(), 1)
                               and t2.dat >= date_sub(curdate(), 8)
                               and t2.create_channel = 1
                            , t2.cnt_creative, 0)) = 0
     ) table1
         left join (
    select a.id 'ID', a.name '代理商', count(distinct b.id) '绑定账户数'
    from makepolo.entity_vendor_account b
             left join makepolo_common.account_admin a on b.company_id = a.id
        and company_type = 0
        and a.status = 1
    where a.id in (
        select t1.id
        from makepolo_common.account_admin t1
                 left join makepolo.makepolo_creative_statistics t2
                           on t1.id = t2.company_id
        where t1.id not in
              ( -- 近5天api创建创意0 有cost
                  select e.company_id
                  from makepolo.vendor_creative_report d
                           left join makepolo.creative_report_dims e
                                     on d.vendor_account_id = e.vendor_account_id
                                         and d.vendor_creative_id = e.vendor_creative_id
                  where d.date <= date_sub(curdate(), 1)
                    and d.date >= date_sub(curdate(), 8)
                  group by 1
                  having sum(if(e.create_channel = 1, cost, 0)) > 0)
          and company_type = 0
          and status = 1
          and date(t1.create_time) < date_sub(curdate(), 8)
          and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
        group by 1
        having sum(
                       if(t2.dat <= date_sub(curdate(), 1)
                              and t2.dat >= date_sub(curdate(), 8)
                              and t2.create_channel = 1
                           , t2.cnt_creative, 0)) = 0
    )
    group by 1, 2
) table2
                   on table1.ID = table2.ID
         left join (
    select eva.id                                                           'ID',
           sum(cost) div 10000                                              "总消耗",
           sum(case when create_channel = 1 then cost else 0 end) div 10000 "api总消耗"
    from makepolo.vendor_creative_report a
             left join makepolo.creative_report_dims b
                       on b.vendor_account_id = a.vendor_account_id
                           and b.vendor_creative_id = a.vendor_creative_id
             left join makepolo.entity_vendor_account eva
                       on eva.id = a.vendor_account_id
    where eva.id in (
        select t1.id
        from makepolo_common.account_admin t1
                 left join makepolo.makepolo_creative_statistics t2
                           on t1.id = t2.company_id
        where t1.id not in
              ( -- 近5天api创建创意0 有cost
                  select e.company_id
                  from makepolo.vendor_creative_report d
                           left join makepolo.creative_report_dims e
                                     on d.vendor_account_id = e.vendor_account_id
                                         and d.vendor_creative_id = e.vendor_creative_id
                  where d.date <= date_sub(curdate(), 1)
                    and d.date >= date_sub(curdate(), 8)
                  group by 1
                  having sum(if(e.create_channel = 1, cost, 0)) > 0)
          and company_type = 0
          and status = 1
          and date(t1.create_time) < date_sub(curdate(), 8)
          and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
        group by 1
        having sum(
                       if(t2.dat <= date_sub(curdate(), 1)
                              and t2.dat >= date_sub(curdate(), 8)
                              and t2.create_channel = 1
                           , t2.cnt_creative, 0)) = 0
    )
    group by 1
) table3
                   on table2.ID = table3.ID
         left join (
    select company_id                                   'ID'
         , sum(cnt_creative)                            "总创建创意数"
         , sum(if(create_channel = 1, cnt_creative, 0)) "api总创建创意数"
    from makepolo.makepolo_creative_statistics
    group by 1
) table4
                   on table4.ID = table3.ID

desc makepolo.makepolo_creative_statistics


-- KA用户
    select 'KA用户' as '用户种类'
      ,split_part(money_format(count(a.company_id)) , '.', 1) as '客户数量'
      , split_part(money_format(sum(ctv_cnt_api)) , '.', 1) as 'api创建创意数'
      , sum(api_cost) as 'api消耗'
      , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost),4) as 'api消耗环比'
      , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api),4) as 'api创建创意数环比'
      , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv),4) as '创建创意数环比'
from
(
select company_id
         , concat(max(b.name), ' ', max(b.id)) as company_name
         , sum(if(date(dat)= date_sub(curdate(), interval 1 day),ctv_cnt,0)) as ctv_cnt
         , sum(if(date(dat)= date_sub(curdate(), interval 1 day),ctv_cnt_api,0)) as ctv_cnt_api
         , sum(if(date(dat)= date_sub(curdate(), interval 2 day),ctv_cnt,0)) as last_ctv
         , sum(if(date(dat)= date_sub(curdate(), interval 2 day),ctv_cnt_api,0)) as last_ctv_api
from rpt_fancy.mkpl_creative a
left join makepolo_common.account_admin b
on b.id = a.company_id
 where date(dat) >= date_sub(curdate(), interval 2 day)
   and date(dat) <= date_sub(curdate(), interval 1 day)
   and b.company_type=0
   and b.status = 1
 group by 1
) a
left join (
        select eva.company_id as company_id
              , sum(cost) div 10000 as cost
              , sum(case when create_channel=1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) div 10000 as api_cost
              , sum(case when create_channel=1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) div 10000 as last_api_cost
          from makepolo.vendor_creative_report cr
          left join makepolo.creative_report_dims  dims
          on dims.vendor_account_id = cr.vendor_account_id
           and dims.vendor_creative_id = cr.vendor_creative_id
          left join makepolo.entity_vendor_account eva on eva.id=cr.vendor_account_id
          where date >= date_sub(curdate(), interval 2 day)
            and date <= date_sub(curdate(), interval 1 day)
          group by 1
) c on c.company_id = a.company_id
where api_cost > 50000
union all
-- 中级用户
select '中级用户'                                                               as '用户种类'
     , split_part(money_format(count(a.company_id)), '.', 1)                as '客户数量'
     , split_part(money_format(sum(ctv_cnt_api)), '.', 1)                   as 'api创建创意数'
     , sum(api_cost)                                                        as 'api消耗'
     , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost), 4)  as 'api消耗环比'
     , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api), 4) as 'api创建创意数环比'
     , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv), 4)             as '创建创意数环比'
from (
         select company_id
              , concat(max(b.name), ' ', max(b.id))                                      as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt, 0))     as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt_api, 0)) as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt, 0))     as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt_api, 0)) as last_ctv_api
         from rpt_fancy.mkpl_creative a
                  left join makepolo_common.account_admin b
                            on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 2 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
           and b.company_type = 0
           and b.status = 1
         group by 1
     ) a
         left join (
    select eva.company_id    as company_id
         , sum(cost) / 10000 as cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) div
           10000             as api_cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) div
           10000             as last_api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date >= date_sub(curdate(), interval 2 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
where api_cost > 10000
  and api_cost < 50000
union all
-- 长尾用户
select '长尾用户'                                                               as '用户种类'
     , split_part(money_format(count(a.company_id)), '.', 1)                as '客户数量'
     , split_part(money_format(sum(ctv_cnt_api)), '.', 1)                   as 'api创建创意数'
     , sum(api_cost)                                                        as 'api消耗'
     , round((sum(api_cost) - sum(last_api_cost)) / sum(last_api_cost), 4)  as 'api消耗环比'
     , round((sum(ctv_cnt_api) - sum(last_ctv_api)) / sum(last_ctv_api), 4) as 'api创建创意数环比'
     , round((sum(ctv_cnt) - sum(last_ctv)) / sum(last_ctv), 4)             as '创建创意数环比'
from (
         select company_id
              , concat(max(b.name), ' ', max(b.id))                                      as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt, 0))     as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), ctv_cnt_api, 0)) as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt, 0))     as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), ctv_cnt_api, 0)) as last_ctv_api
         from rpt_fancy.mkpl_creative a
                  left join makepolo_common.account_admin b
                            on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 2 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
           and b.company_type = 0
           and b.status = 1
         group by 1
     ) a
         left join (
    select eva.company_id    as company_id
         , sum(cost) / 10000 as cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 1 day) then cost else 0 end) div
           10000             as api_cost
         , sum(case when create_channel = 1 and date = date_sub(curdate(), interval 2 day) then cost else 0 end) div
           10000             as last_api_cost
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva on eva.id = cr.vendor_account_id
    where date >= date_sub(curdate(), interval 2 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1
) c on c.company_id = a.company_id
where api_cost < 10000


select sum(cost) / 10000                                              cost,
       sum(case when create_channel = 1 then cost else 0 end) / 10000 api_cost
from makepolo.vendor_creative_report table1
         left join makepolo.creative_report_dims table2
                   on table2.vendor_account_id = table1.vendor_account_id
                       and table2.vendor_creative_id = table1.vendor_creative_id
where company_id = 324



select table1.ID
     , table1.代理商
     , table2.绑定账户数
     , ifnull(split_part(money_format(总消耗), '.', 1), '-')       '总消耗'
     , ifnull(split_part(money_format(api总消耗), '.', 1), '-')    'api总消耗'
     , ifnull(split_part(money_format(总创建创意数), '.', 1), '-')    '总创建创意数'
     , ifnull(split_part(money_format(api总创建创意数), '.', 1), '-') 'api总创建创意数'
from (
         select t1.id           'ID'
              , t1.company_name '代理商'
         from makepolo_common.account_admin t1
                  left join makepolo.makepolo_creative_statistics t2
                            on t1.id = t2.company_id
         where t1.id not in
               ( -- 近5天api创建创意0 有cost
                   select e.company_id
                   from makepolo.vendor_creative_report d
                            left join makepolo.creative_report_dims e
                                      on d.vendor_account_id = e.vendor_account_id
                                          and d.vendor_creative_id = e.vendor_creative_id
                   where d.date <= date_sub(curdate(), 1)
                     and d.date >= date_sub(curdate(), 8)
                   group by 1
                   having sum(if(e.create_channel = 1, cost, 0)) > 0)
           and company_type = 0
           and status = 1
           and date(t1.create_time) < date_sub(curdate(), 8)
           and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
         group by 1, 2
         having sum(
                        if(t2.dat <= date_sub(curdate(), 1)
                               and t2.dat >= date_sub(curdate(), 8)
                               and t2.create_channel = 1
                            , t2.cnt_creative, 0)) = 0
     ) table1
         left join (
    select a.id 'ID', a.name '代理商', count(distinct b.id) '绑定账户数'
    from makepolo.entity_vendor_account b
             left join makepolo_common.account_admin a on b.company_id = a.id
        and company_type = 0
        and a.status = 1
    where a.id in (
        select t1.id
        from makepolo_common.account_admin t1
                 left join makepolo.makepolo_creative_statistics t2
                           on t1.id = t2.company_id
        where t1.id not in
              ( -- 近5天api创建创意0 有cost
                  select e.company_id
                  from makepolo.vendor_creative_report d
                           left join makepolo.creative_report_dims e
                                     on d.vendor_account_id = e.vendor_account_id
                                         and d.vendor_creative_id = e.vendor_creative_id
                  where d.date <= date_sub(curdate(), 1)
                    and d.date >= date_sub(curdate(), 8)
                  group by 1
                  having sum(if(e.create_channel = 1, cost, 0)) > 0)
          and company_type = 0
          and status = 1
          and date(t1.create_time) < date_sub(curdate(), 8)
          and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
        group by 1
        having sum(
                       if(t2.dat <= date_sub(curdate(), 1)
                              and t2.dat >= date_sub(curdate(), 8)
                              and t2.create_channel = 1
                           , t2.cnt_creative, 0)) = 0
    )
    group by 1, 2
) table2
                   on table1.ID = table2.ID
         left join (
    select eva.company_id                                                   'ID',
           sum(cost) div 10000                                              "总消耗",
           sum(case when create_channel = 1 then cost else 0 end) div 10000 "api总消耗"
    from makepolo.vendor_creative_report a
             left join makepolo.creative_report_dims b
                       on b.vendor_account_id = a.vendor_account_id
                           and b.vendor_creative_id = a.vendor_creative_id
             left join makepolo.entity_vendor_account eva
                       on eva.id = a.vendor_account_id
    where eva.company_id in (
        select t1.id
        from makepolo_common.account_admin t1
                 left join makepolo.makepolo_creative_statistics t2
                           on t1.id = t2.company_id
        where t1.id not in
              ( -- 近5天api创建创意0 有cost
                  select e.company_id
                  from makepolo.vendor_creative_report d
                           left join makepolo.creative_report_dims e
                                     on d.vendor_account_id = e.vendor_account_id
                                         and d.vendor_creative_id = e.vendor_creative_id
                  where d.date <= date_sub(curdate(), 1)
                    and d.date >= date_sub(curdate(), 8)
                  group by 1
                  having sum(if(e.create_channel = 1, cost, 0)) > 0)
          and company_type = 0
          and status = 1
          and date(t1.create_time) < date_sub(curdate(), 8)
          and t1.id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
        group by 1
        having sum(
                       if(t2.dat <= date_sub(curdate(), 1)
                              and t2.dat >= date_sub(curdate(), 8)
                              and t2.create_channel = 1
                           , t2.cnt_creative, 0)) = 0
    )
    group by 1
) table3
                   on table2.ID = table3.ID
         left join (
    select company_id                                   'ID'
         , sum(cnt_creative)                            "总创建创意数"
         , sum(if(create_channel = 1, cnt_creative, 0)) "api总创建创意数"
    from makepolo.makepolo_creative_statistics
    group by 1
) table4
                   on table4.ID = table3.ID



select sum(cost) div 10000                                              "总消耗",
       sum(case when create_channel = 1 then cost else 0 end) div 10000 "api总消耗"
from makepolo.vendor_creative_report a
         left join makepolo.creative_report_dims b
                   on b.vendor_account_id = a.vendor_account_id
                       and b.vendor_creative_id = a.vendor_creative_id
         left join makepolo.entity_vendor_account eva
                   on eva.id = a.vendor_account_id
where eva.company_id = 324

select *
from makepolo.entity_vendor_account
limit 1


select c.type, ifnull(cou, 0) '昨日新增客户数'
from (select 1 type
      union
      select 2 type) c
         left join (
    select if(vendor_id = 1, 1, 2) type,
           count(distinct a.id)    cou
    from makepolo_common.account_admin a
             left join makepolo.entity_vendor_account b
                       on a.id = b.company_id
    where date(a.create_time) = date_sub(curdate(), 1)
      and company_type = 0
      and a.status = 1
    group by 1
) d
                   on c.type = d.type
order by 1



select if(vendor_id = 1, 1, 2)         type,
       ifnull(count(distinct a.id), 0) '昨日新增客户数'
from makepolo_common.account_admin a
         left join makepolo.entity_vendor_account b
                   on a.id = b.company_id
where date(a.create_time) = date_sub(curdate(), 1)
  and company_type = 0
  and a.status = 1
group by 1
order by 1


select count(id)
from makepolo_common.account_admin



select ad.id,
       ad.name,
       ad.create_time,
       sum(if(date = date_sub(curdate(), 1), cost, 0)) div 10000                                          "总消耗",
       sum(case when create_channel = 1 and date = date_sub(curdate(), 1) then cost else 0 end) div 10000 "api总消耗"
from makepolo_common.account_admin ad
         left join makepolo.entity_vendor_account eva
                   on ad.id = eva.company_id
         left join makepolo.vendor_creative_report a
                   on eva.id = a.vendor_account_id
         left join makepolo.creative_report_dims b
                   on b.vendor_account_id = a.vendor_account_id
                       and b.vendor_creative_id = a.vendor_creative_id
where company_type = 0
  and status = 1

select count(distinct id)
from makepolo_common.account_admin


select tmp.id           id
     , tmp.vendor_id as vendor_id
     , tmp.name
     , ctv_cnt      -- 总创建创意
     , ctv_cnt_api  -- api创建创意
     , last_ctv     -- 前日创建创意
     , last_ctv_api -- 前日api创建创意
     , create_time  -- 创建时间
     , cst_ysd      -- 昨日总消耗
     , api_cst      -- 昨日api消耗
     , last_api_cst -- 前日api消耗
     , api_cst8     -- 8日前api消耗
     , api_cst7ds   -- 连续7天api消耗
     , bind_acct    -- 昨日绑定账户数
     , pro_num      -- 昨日创建项目数
from (select id,
             1 vendor_id,
             name
      from makepolo_common.account_admin
      where company_type = 0
        and status = 1
        and id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)
      union all
      select id,
             2 vendor_id,
             name
      from makepolo_common.account_admin
      where company_type = 0
        and status = 1
        and id not in (1, 122, 139, 178, 176, 175, 168, 199, 236, 256, 303, 150324)) tmp
         left join
     (
         select b.id
              , a.vendor_id                         as vendor_id
              , concat(max(b.name), ' ', max(b.id)) as company_name
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day), cnt_creative,
                       0))                          as ctv_cnt
              , sum(if(date(dat) = date_sub(curdate(), interval 1 day) and create_channel = 1, cnt_creative,
                       0))                          as ctv_cnt_api
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day), cnt_creative,
                       0))                          as last_ctv
              , sum(if(date(dat) = date_sub(curdate(), interval 2 day) and create_channel = 1, cnt_creative,
                       0))                          as last_ctv_api
              , max(date(b.create_time))            as create_time
         from makepolo.makepolo_creative_statistics a
                  right join makepolo_common.account_admin b
                             on b.id = a.company_id
         where date(dat) >= date_sub(curdate(), interval 8 day)
           and date(dat) <= date_sub(curdate(), interval 1 day)
         group by 1, 2
     ) a
     on tmp.id = a.id and tmp.vendor_id = a.vendor_id
         left join (
    select eva.company_id                                                                                   as company_id
         , cr.vendor_id                                                                                     as vendor_id
         , sum(case when date = date_sub(curdate(), 1) then cost else 0 end) / 10000                        as cst_ysd
         , sum(case when create_channel = 1 and date = date_sub(curdate(), 1) then cost else 0 end) / 10000 as api_cst
         , sum(case when create_channel = 1 and date = date_sub(curdate(), 2) then cost else 0 end) /
           10000                                                                                            as last_api_cst
         , sum(case when create_channel = 1 and date = date_sub(curdate(), 8) then cost else 0 end) / 10000 as api_cst8
         , sum(case
                   when create_channel = 1 and date >= date_sub(curdate(), 7)
                       and date <= date_sub(curdate(), 1) then cost
                   else 0 end) /
           10000                                                                                            as api_cst7ds
         , count(distinct if(date(eva.create_time) = date_sub(curdate(), 1), eva.id, 0))                    as bind_acct
         , count(distinct if(date(pro.create_time) = date_sub(curdate(), 1), pro.id, 0))                    as pro_num
    from makepolo.vendor_creative_report cr
             left join makepolo.creative_report_dims dims
                       on dims.vendor_account_id = cr.vendor_account_id
                           and dims.vendor_creative_id = cr.vendor_creative_id
             left join makepolo.entity_vendor_account eva
                       on eva.id = cr.vendor_account_id
             left join makepolo.project pro on dims.project_id = pro.id
    where date >= date_sub(curdate(), interval 8 day)
      and date <= date_sub(curdate(), interval 1 day)
    group by 1, 2
) c on c.company_id = tmp.id and tmp.vendor_id = c.vendor_id

desc makepolo.ad_creative
