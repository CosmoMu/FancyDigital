 with data_detail as (
    select *
    , if(action='imp', 1, 0 ) as imp
    , if(action='clk', 1, 0 ) as clk
    from
        (
         select thisdate
            , cast(replace(timestamp, '_', ' ') as timestamp) as timestp
            , ext_request_id as r_id
            , ext_vendor_id as vid
            , ua_id_v2 as ua_id
            , ip as ip
            , if(ext_platform='Android',2,1) as os
            , upper(trim(case
            when length(ext_mobile_oaid) > 15  then ext_mobile_oaid
            when length(ext_user_id)  in (32,36)  then ext_user_id
            when length(ext_mobile_android_id_md5) = 32 then ext_mobile_android_id_md5
            when length(ext_mobile_mac_md5)  = 32 then ext_mobile_mac_md5
            else cast(random(100000000000000) as varchar)
            end)) as did
            , ext_mobile_android_id_md5 as aid
            , if(length(ext_user_id) = 32,ext_user_id,'') as imei
            , ext_mobile_idfa  as idfa
            , ext_mobile_oaid as oaid
            , substr(cast(ua_id_v2 as varchar),1,8) as model
            , substr(replace(timestamp, '_', ' '), 1, 16) as minute_str
            , 1 as device_type
            , ext_advertiser_id as advertiser_id
                    , '' as mac
        , upper(trim(if(length(ext_mobile_mac_md5)  > 0 and ext_mobile_mac_md5 <> '__MAC1__' , ext_mobile_mac_md5, '')))  as mac1
            , 'imp' as action
    from dwd.d_ad_impression a
    where thisdate='2020-12-29' and ext_order_id =2884
       union all

        select thisdate
        , cast(replace(time, '_', ' ') as timestamp) as timestp
        , ext_request_id as r_id
        , ext_vendor_id as vid
        , ua_id_v2 as ua_id
        , ip as ip
        , if(ext_platform='Android',2,1) as os
        , upper(trim(case
            when length(ext_mobile_oaid) > 15  then ext_mobile_oaid
            when length(ext_user_id)  in (32,36)  then ext_user_id
            when length(ext_mobile_android_id_md5) = 32 then ext_mobile_android_id_md5
            when length(ext_mobile_mac_md5)  = 32 then ext_mobile_mac_md5
            else cast(random(100000000000000) as varchar)
            end)) as did
        , ext_mobile_android_id_md5 as aid
        , if(length(ext_user_id) = 32,ext_user_id,'') as imei
        , ext_mobile_idfa  as idfa
        , ext_mobile_oaid as oaid
        , substr(cast(ua_id_v2 as varchar),1,8) as model
        , substr(replace(time, '_', ' '), 1, 16) as minute_str
        , 1 as device_type
        , ext_advertiser_id as advertiser_id
                    , '' as mac
        , upper(trim(if(length(ext_mobile_mac_md5)  > 0 and ext_mobile_mac_md5 <> '__MAC1__' , ext_mobile_mac_md5, '')))  as mac1
        , 'clk' as action

from dwd.d_ad_clicklog_day a
    where thisdate='2020-12-29' and ext_order_id =2884



            ))


select thisdate, 'dsp' as type, vid,  advertiser_id, sum(imp) as imp, sum(clk) as clk
    , sum(case
        when d_is_did_lost    = 1  then imp
        when d_is_did_illegal = 1  then imp
        when did_minute_imp > 5 or aid_minute_imp > 5 or imei_minute_imp > 5 or oaid_minute_imp > 5 or mac_minute_imp > 5 or mac1_minute_imp > 5 or idfa_minute_imp > 5  then imp
        when diff_imp_scds     < 16 then imp
        when d_did_md_cnt > 2 or d_aid_md_cnt > 2 or d_imei_md_cnt > 2 or d_oaid_md_cnt > 2 or d_mac_md_cnt > 2 or d_mac1_md_cnt > 2 or d_idfa_md_cnt > 2  then imp
        when d_did_os_cnt > 1 or d_aid_os_cnt > 1 or d_imei_os_cnt > 1 or d_oaid_os_cnt > 1 or d_mac_os_cnt > 1 or d_mac1_os_cnt > 1 or d_idfa_os_cnt > 1  then imp
        when d_imei_aid_cnt > 2 or a_imei_aid_cnt > 2 or d_mac_aid_cnt > 2 or d_mac1_aid_cnt > 2 or a_mac_aid_cnt > 2 or a_mac1_aid_cnt > 2 then imp
        when d_aid_imei_cnt > 2 or i_aid_imei_cnt > 2 or d_mac_imei_cnt > 2 or d_mac1_imei_cnt > 2 or i_mac_imei_cnt > 2 or i_mac1_imei_cnt > 2 then imp
        when d_is_did_illegal_2os = 1 then imp
        when d_idfa_mac_cnt > 2 or d_idfa_mac1_cnt > 2 or m_idfa_mac_cnt > 2 or m_idfa_mac1_cnt > 2 or d_imei_mac_cnt > 2 or d_imei_mac1_cnt > 2 or m_imei_mac_cnt > 2 or m_imei_mac1_cnt > 2 then imp
        when d_mac_idfa_cnt > 2 or d_mac1_idfa_cnt > 2 or i_mac_idfa_cnt > 2 or i_mac1_idfa_cnt > 2 then imp
        else 0
      end) as sivt_imp
    , sum(case
        when d_is_did_lost    = 1  then clk
        when d_is_did_illegal = 1  then clk
        when did_minute_clk > 4 or aid_minute_clk > 4 or imei_minute_clk > 4 or oaid_minute_clk > 4 or mac_minute_clk > 4 or mac1_minute_clk > 4 or idfa_minute_clk > 4  then clk
--         when diff_clk_scds     < 16 then clk
        when d_did_md_cnt > 2 or d_aid_md_cnt > 2 or d_imei_md_cnt > 2 or d_oaid_md_cnt > 2 or d_mac_md_cnt > 2 or d_mac1_md_cnt > 2 or d_idfa_md_cnt > 2  then clk
        when d_did_os_cnt > 1 or d_aid_os_cnt > 1 or d_imei_os_cnt > 1 or d_oaid_os_cnt > 1 or d_mac_os_cnt > 1 or d_mac1_os_cnt > 2 or d_idfa_os_cnt > 1   then clk
        when d_imei_aid_cnt > 2 or a_imei_aid_cnt > 2 or d_mac_aid_cnt > 2 or d_mac1_aid_cnt > 2 or a_mac_aid_cnt > 2 or a_mac1_aid_cnt > 2 then clk
        when d_aid_imei_cnt > 2 or i_aid_imei_cnt > 2 or d_mac_imei_cnt > 2 or d_mac1_imei_cnt > 2 or i_mac_imei_cnt > 2 or i_mac1_imei_cnt > 2 then clk
        when d_is_did_illegal_2os = 1 then clk
        when d_idfa_mac_cnt > 2 or d_idfa_mac1_cnt > 2 or m_idfa_mac_cnt > 2 or m_idfa_mac1_cnt > 2 or d_imei_mac_cnt > 2 or d_imei_mac1_cnt > 2 or m_imei_mac_cnt > 2 or m_imei_mac1_cnt > 2 then clk
        when d_mac_idfa_cnt > 2 or d_mac1_idfa_cnt > 2 or i_mac_idfa_cnt > 2 or i_mac1_idfa_cnt > 2 then clk
        else 0
      end) as sivt_clk
    , sum(if(d_is_did_lost = 1, imp, 0))                                                                                                                     as mb_without_device_id_imp
    , sum(if(d_is_did_illegal = 1, imp, 0))                                                                                                                  as deviceId_illegal_imp
    , sum(if(did_minute_imp > 5 or aid_minute_imp > 5 or imei_minute_imp > 5 or oaid_minute_imp > 5 or mac_minute_imp > 5 or mac1_minute_imp > 5 or idfa_minute_imp > 5, imp, 0))   as excessive_imp
    , sum(if(diff_imp_scds < 16, imp, 0))                                                                                                                    as continuous_imp
    , sum(if(d_did_md_cnt > 2 or d_aid_md_cnt > 2 or d_imei_md_cnt > 2 or d_oaid_md_cnt > 2 or d_mac_md_cnt > 2 or d_mac1_md_cnt > 2 or d_idfa_md_cnt > 2, imp, 0))               as multi_device_imp
    , sum(if(d_did_os_cnt > 1 or d_aid_os_cnt > 1 or d_imei_os_cnt > 1 or d_oaid_os_cnt > 1 or d_mac_os_cnt > 1 or d_mac1_os_cnt > 2 or d_idfa_os_cnt > 1, imp, 0))               as multi_os_imp
    , sum(if(d_imei_aid_cnt > 2 or a_imei_aid_cnt > 2 or d_mac_aid_cnt > 2 or d_mac1_aid_cnt > 2 or a_mac_aid_cnt > 2 or a_mac1_aid_cnt > 2, imp, 0))                                                    as multi_android_id_imp
    , sum(if(d_aid_imei_cnt > 2 or i_aid_imei_cnt > 2 or d_mac_imei_cnt > 2 or d_mac1_imei_cnt > 2 or i_mac_imei_cnt > 2 or i_mac1_imei_cnt > 2, imp, 0))                                                  as multi_imei_imp
    , sum(if(d_is_did_illegal_2os = 1, imp, 0))                                                                                                              as illeagal_os_imp
    , sum(if(d_idfa_mac_cnt > 2 or d_idfa_mac1_cnt > 2 or m_idfa_mac_cnt > 2 or m_idfa_mac1_cnt > 2 or d_imei_mac_cnt > 2 or d_imei_mac1_cnt > 2 or m_imei_mac_cnt > 2 or m_imei_mac1_cnt > 2, imp, 0))                                                  as multi_mac_imp
    , sum(if(d_mac_idfa_cnt > 2 or d_mac1_idfa_cnt > 2 or i_mac_idfa_cnt > 2 or i_mac1_idfa_cnt > 2, imp, 0))                                                                                              as multi_idfa_imp

    -- SIVT Click Detail
    , sum(if(d_is_did_lost = 1, clk, 0))                                                                                                                     as mb_without_device_id_clk
    , sum(if(d_is_did_illegal = 1, clk, 0))                                                                                                                  as deviceId_illegal_clk
    , sum(if(did_minute_clk > 4 or aid_minute_clk > 4 or imei_minute_clk > 4 or oaid_minute_clk > 4 or mac_minute_clk > 4 or mac1_minute_clk > 4 or idfa_minute_clk > 4, clk, 0))   as excessive_clk
    , sum(if(d_did_md_cnt > 2 or d_aid_md_cnt > 2 or d_imei_md_cnt > 2 or d_oaid_md_cnt > 2 or d_mac_md_cnt > 2 or d_mac1_md_cnt > 2 or d_idfa_md_cnt > 2, clk, 0))               as multi_device_clk
    , sum(if(d_did_os_cnt > 1 or d_aid_os_cnt > 1 or d_imei_os_cnt > 1 or d_oaid_os_cnt > 1 or d_mac_os_cnt > 1 or d_mac1_os_cnt > 1 or d_idfa_os_cnt > 1, clk, 0))               as multi_os_clk
    , sum(if(d_imei_aid_cnt > 2 or a_imei_aid_cnt > 2 or d_mac_aid_cnt > 2 or d_mac1_aid_cnt > 2 or a_mac_aid_cnt > 2 or a_mac1_aid_cnt > 2, clk, 0))                                                    as multi_android_id_clk
    , sum(if(d_aid_imei_cnt > 2 or i_aid_imei_cnt > 2 or d_mac_imei_cnt > 2 or d_mac1_imei_cnt > 2 or i_mac_imei_cnt > 2 or i_mac1_imei_cnt > 2, clk, 0))                                                  as multi_imei_clk
    , sum(if(d_is_did_illegal_2os = 1, clk, 0))                                                                                                              as illeagal_os_clk
    , sum(if(d_idfa_mac_cnt > 2 or d_idfa_mac1_cnt > 2 or m_idfa_mac_cnt > 2 or m_idfa_mac1_cnt > 2 or d_imei_mac_cnt > 2 or d_imei_mac1_cnt > 2 or m_imei_mac_cnt > 2 or m_imei_mac1_cnt > 2, clk, 0))                                                  as multi_mac_clk
    , sum(if(d_mac_idfa_cnt > 2 or d_mac1_idfa_cnt > 2 or i_mac_idfa_cnt > 2 or i_mac1_idfa_cnt > 2, clk, 0))                                                                                              as multi_idfa_clk


from
(
    select *
        -- Device ID Lost
        , max(is_did_lost)  over (partition by did, thisdate) as d_is_did_lost
        -- Illegal/Nonstandard DeviceID
        , max(is_did_illegal) over (partition by did, thisdate) as d_is_did_illegal

        -- multi device type
        , max(did_md_cnt)   over (partition by did, thisdate) as d_did_md_cnt
        , max(aid_md_cnt)   over (partition by did, thisdate) as d_aid_md_cnt
        , max(imei_md_cnt)  over (partition by did, thisdate) as d_imei_md_cnt
        , max(oaid_md_cnt)  over (partition by did, thisdate) as d_oaid_md_cnt
        , max(mac_md_cnt)   over (partition by did, thisdate) as d_mac_md_cnt
        , max(mac1_md_cnt)  over (partition by did, thisdate) as d_mac1_md_cnt
        , max(idfa_md_cnt)  over (partition by did, thisdate) as d_idfa_md_cnt

        -- multi os
        , max(did_os_cnt)   over (partition by did, thisdate) as d_did_os_cnt
        , max(aid_os_cnt)   over (partition by did, thisdate) as d_aid_os_cnt
        , max(imei_os_cnt)  over (partition by did, thisdate) as d_imei_os_cnt
        , max(oaid_os_cnt)  over (partition by did, thisdate) as d_oaid_os_cnt
        , max(mac_os_cnt)   over (partition by did, thisdate) as d_mac_os_cnt
        , max(mac1_os_cnt)  over (partition by did, thisdate) as d_mac1_os_cnt
        , max(idfa_os_cnt)  over (partition by did, thisdate) as d_idfa_os_cnt

        -- multi android id
        , max(imei_aid_cnt) over (partition by did, thisdate) as d_imei_aid_cnt
        , max(imei_aid_cnt) over (partition by w_aid, thisdate) as a_imei_aid_cnt
        , max(mac_aid_cnt)  over (partition by did, thisdate) as d_mac_aid_cnt
        , max(mac_aid_cnt)  over (partition by w_aid, thisdate) as a_mac_aid_cnt
        , max(mac1_aid_cnt) over (partition by did, thisdate) as d_mac1_aid_cnt
        , max(mac1_aid_cnt) over (partition by w_aid, thisdate) as a_mac1_aid_cnt

        -- multi imei
        , max(aid_imei_cnt) over (partition by did, thisdate) as d_aid_imei_cnt
        , max(aid_imei_cnt) over (partition by w_imei, thisdate) as i_aid_imei_cnt
        , max(mac_imei_cnt) over (partition by did, thisdate) as d_mac_imei_cnt
        , max(mac_imei_cnt) over (partition by w_imei, thisdate) as i_mac_imei_cnt
        , max(mac1_imei_cnt) over (partition by did, thisdate) as d_mac1_imei_cnt
        , max(mac1_imei_cnt) over (partition by w_imei, thisdate) as i_mac1_imei_cnt

        -- Illegal ID To OS
        , max(is_did_illegal_2os) over (partition by did, thisdate) as d_is_did_illegal_2os

        -- multi mac
        , max(idfa_mac_cnt) over (partition by did, thisdate) as d_idfa_mac_cnt
        , max(idfa_mac_cnt) over (partition by w_mac, thisdate) as m_idfa_mac_cnt
        , max(idfa_mac1_cnt) over (partition by did, thisdate) as d_idfa_mac1_cnt
        , max(idfa_mac1_cnt) over (partition by w_mac1, thisdate) as m_idfa_mac1_cnt
        , max(imei_mac_cnt) over (partition by did, thisdate) as d_imei_mac_cnt
        , max(imei_mac_cnt) over (partition by w_mac, thisdate) as m_imei_mac_cnt
        , max(imei_mac1_cnt) over (partition by did, thisdate) as d_imei_mac1_cnt
        , max(imei_mac1_cnt) over (partition by w_mac1, thisdate) as m_imei_mac1_cnt

        --  multi idfa
        , max(mac_idfa_cnt) over (partition by did, thisdate) as d_mac_idfa_cnt
        , max(mac_idfa_cnt) over (partition by w_idfa, thisdate) as i_mac_idfa_cnt
        , max(mac1_idfa_cnt) over (partition by did, thisdate) as d_mac1_idfa_cnt
        , max(mac1_idfa_cnt) over (partition by w_idfa, thisdate) as i_mac1_idfa_cnt

        -- 曝光过高
        , sum(imp) over (partition by did, minute_str)    as did_minute_imp
        , sum(imp) over (partition by w_aid, minute_str)  as aid_minute_imp
        , sum(imp) over (partition by w_imei, minute_str) as imei_minute_imp
        , sum(imp) over (partition by w_oaid, minute_str) as oaid_minute_imp
        , sum(imp) over (partition by w_mac, minute_str)  as mac_minute_imp
        , sum(imp) over (partition by w_mac1, minute_str) as mac1_minute_imp
        , sum(imp) over (partition by w_idfa, minute_str) as idfa_minute_imp

        -- 点击频繁
        , sum(clk) over (partition by did, minute_str)    as did_minute_clk
        , sum(clk) over (partition by w_aid, minute_str)  as aid_minute_clk
        , sum(clk) over (partition by w_imei, minute_str) as imei_minute_clk
        , sum(clk) over (partition by w_oaid, minute_str) as oaid_minute_clk
        , sum(clk) over (partition by w_mac, minute_str)  as mac_minute_clk
        , sum(clk) over (partition by w_mac1, minute_str) as mac1_minute_clk
        , sum(clk) over (partition by w_idfa, minute_str) as idfa_minute_clk

        -- 曝光碰撞
        , if(pre_imp_diff_scds < post_imp_diff_scds, pre_imp_diff_scds, post_imp_diff_scds) as diff_imp_scds
        , if(pre_clk_diff_scds < post_clk_diff_scds, pre_clk_diff_scds, post_clk_diff_scds) as diff_clk_scds
    from
    (
        select *
            -- multi device type
            , approx_distinct(ua_id)  over (partition by did, thisdate)    as did_md_cnt
            , approx_distinct(ua_id)  over (partition by w_aid, thisdate)  as aid_md_cnt
            , approx_distinct(ua_id)  over (partition by w_imei, thisdate) as imei_md_cnt
            , approx_distinct(ua_id)  over (partition by w_oaid, thisdate) as oaid_md_cnt
            , approx_distinct(ua_id)  over (partition by w_mac, thisdate)  as mac_md_cnt
            , approx_distinct(ua_id)  over (partition by w_mac1, thisdate) as mac1_md_cnt
            , approx_distinct(ua_id)  over (partition by w_idfa, thisdate) as idfa_md_cnt

            -- multi os
            , approx_distinct(os)     over (partition by did, thisdate)    as did_os_cnt
            , approx_distinct(os)     over (partition by w_aid, thisdate)  as aid_os_cnt
            , approx_distinct(os)     over (partition by w_imei, thisdate) as imei_os_cnt
            , approx_distinct(os)     over (partition by w_oaid, thisdate) as oaid_os_cnt
            , approx_distinct(os)     over (partition by w_mac, thisdate)  as mac_os_cnt
            , approx_distinct(os)     over (partition by w_mac1, thisdate) as mac1_os_cnt
            , approx_distinct(os)     over (partition by w_idfa, thisdate) as idfa_os_cnt

            -- multi android id
            , approx_distinct(m_aid)  over (partition by w_imei, thisdate) as imei_aid_cnt -- multi android id (imei)
            , approx_distinct(m_aid)  over (partition by w_mac, thisdate)  as mac_aid_cnt  -- multi android id (mac)
            , approx_distinct(m_aid)  over (partition by w_mac1, thisdate) as mac1_aid_cnt -- multi android id (mac1)

            -- multi imei
            , approx_distinct(m_imei) over (partition by w_aid, thisdate)  as aid_imei_cnt -- multi imei (android id)
            , approx_distinct(m_imei) over (partition by w_mac, thisdate)  as mac_imei_cnt -- multi imei (mac)
            , approx_distinct(m_imei) over (partition by w_mac1, thisdate) as mac1_imei_cnt -- multi imei (mac1)

            -- multi mac
            , approx_distinct(m_mac)  over (partition by w_idfa, thisdate) as idfa_mac_cnt -- multi mac (idfa)
            , approx_distinct(m_mac)  over (partition by w_imei, thisdate) as imei_mac_cnt -- multi mac (imei)
            , approx_distinct(m_mac1) over (partition by w_idfa, thisdate) as idfa_mac1_cnt -- multi mac1 (idfa)
            , approx_distinct(m_mac1) over (partition by w_imei, thisdate) as imei_mac1_cnt -- multi mac1 (imei)

            -- multi idfa
            , approx_distinct(m_idfa) over (partition by w_mac, thisdate)  as mac_idfa_cnt -- multi idfa (mac)
            , approx_distinct(m_idfa) over (partition by w_mac1, thisdate) as mac1_idfa_cnt -- multi idfa (mac1)

            -- continuous imp/clk
            , date_diff('second', pre_imp_timestp, timestp)  as pre_imp_diff_scds
            , date_diff('second', timestp, post_imp_timestp) as post_imp_diff_scds
            , date_diff('second', pre_clk_timestp, timestp)  as pre_clk_diff_scds
            , date_diff('second', timestp, post_clk_timestp) as post_clk_diff_scds
        from
        (
                select *
                , if( length(did)<16, 1, 0) as is_did_lost
                , case
                    when length(aid) = 32 and regexp_like(aid, '^[0-9A-Fa-f]+$') then 0
                    when length(aid) > 0  then 1
                    when length(imei) = 32 and regexp_like(imei, '^[0-9A-Fa-f]+$') then 0
                    when length(imei) > 0  then 1
                    when length(idfa) = 36 and regexp_like(idfa, '^[0-9A-Fa-f-]+$') then 0
                    when length(idfa) > 0  then 1
                    when length(mac)  = 32 and regexp_like(mac, '^[0-9A-Fa-f]+$') then 0
                    when length(mac)  > 0  then 1
                    when length(mac1) = 32 and regexp_like(mac1, '^[0-9A-Fa-f]+$') then 0
                    when length(mac1) > 0 then 1
                    when length(oaid) in (16, 32, 36, 64) and regexp_like(oaid, '^[0-9A-Fa-f-]+$') then 0
                    when length(oaid) > 0  then 1
                    else 0
                  end as is_did_illegal
                ,  case
                    when os = 0 and idfa <> '' then 1
                    when os = 1 and aid  <> '' then 1
                    when os = 1 and imei <> '' then 1
                    when os = 1 and oaid <> '' then 1
                    else 0
                  end as is_did_illegal_2os
                , case
                    when mac = 'E3F5536A141811DB40EFD6400F1D0A4E' then NULL
                    when mac = '35B9AB5A36F3234DD26DB357FD4A0DC1' then NULL
                     when mac = '528C8E6CD4A3C6598999A0E9DF15AD32' then NULL
                     when mac = '0F607264FC6318A92B9E13C65DB7CD3C' then NULL
                    when mac = 'D41D8CD98F00B204E9800998ECF8427E' then NULL
                    when mac = '' then NULL
                    else mac
                end as m_mac
                , case
                    when mac = 'E3F5536A141811DB40EFD6400F1D0A4E' then did
                    when mac = '35B9AB5A36F3234DD26DB357FD4A0DC1' then did
                     when mac = '528C8E6CD4A3C6598999A0E9DF15AD32' then did
                     when mac = '0F607264FC6318A92B9E13C65DB7CD3C' then did
                    when mac = 'D41D8CD98F00B204E9800998ECF8427E' then did
                    when mac = '' then did
                    else mac
                end as w_mac
                , case
                     when mac1 = 'E3F5536A141811DB40EFD6400F1D0A4E' then NULL
                     when mac1 = '35B9AB5A36F3234DD26DB357FD4A0DC1' then NULL
                    when mac1 = '528C8E6CD4A3C6598999A0E9DF15AD32' then NULL
                    when mac1 = '0F607264FC6318A92B9E13C65DB7CD3C' then NULL
                    when mac1 = 'D41D8CD98F00B204E9800998ECF8427E' then NULL
                    when mac1 = '' then NULL
                    else mac1
                end as m_mac1
                , case
                     when mac1 = 'E3F5536A141811DB40EFD6400F1D0A4E' then did
                    when mac1 = '35B9AB5A36F3234DD26DB357FD4A0DC1' then did
                    when mac1 = '528C8E6CD4A3C6598999A0E9DF15AD32' then did
                    when mac1 = '0F607264FC6318A92B9E13C65DB7CD3C' then did
                    when mac1 = 'D41D8CD98F00B204E9800998ECF8427E' then did
                    when mac1 = '' then did
                    else mac1
                end as w_mac1
                , if(aid <> '' , aid, NULL) as m_aid   , if(aid <> '', aid, did)   as w_aid
                , if(imei <> '' and device_type <> 5, imei, NULL) as m_imei, if(imei <> '' and device_type <> 5, imei, did) as w_imei
                , if(idfa <> '' and device_type <> 5, idfa, NULL) as m_idfa, if(idfa <> '' and device_type <> 5, idfa, did) as w_idfa
                , if(oaid <> '' , oaid, NULL) as m_oaid, if(oaid <> '', oaid, did) as w_oaid
                , LAG(timestp, 1,  cast('1970-01-01 00:00:00' as timestamp)) over (partition by did, action, thisdate order by timestp) as pre_imp_timestp
                , LEAD(timestp, 1, cast('2099-12-31 00:00:00' as timestamp)) over (partition by did, action, thisdate order by timestp) as post_imp_timestp
                , LAG(timestp, 1,  cast('1970-01-01 00:00:00' as timestamp)) over (partition by did, action, thisdate order by timestp) as pre_clk_timestp
                , LEAD(timestp, 1, cast('2099-12-31 00:00:00' as timestamp)) over (partition by did, action, thisdate order by timestp) as post_clk_timestp
            from data_detail a
        ) b
    ) c
)d
group by 1, 2, 3, 4