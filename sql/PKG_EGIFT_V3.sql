--------------------------------------------------------
--  File created - Thursday-December-22-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body PKG_EGIFT_V3
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEALTODAY_DEV"."PKG_EGIFT_V3" AS
--
PROCEDURE GetBannerEgiftV3(
      p_position varchar2,
      p_channelId varchar2,
      p_locationId number,
      ret out refcur
    ) AS
  BEGIN
    open ret for
      select a.* from ADV_ADVERTISES a, ADV_POSITIONS b 
      WHERE a.ADVERTISE_POSITIONID = b.POS_ID  
      AND a.ADVERTISE_ENABLE = 1 AND (sysdate between a.ADVERTISE_STARTDATE and a.ADVERTISE_ENDDATE)
      AND (a.LOCATION_ID = p_locationid or a.LOCATION_ID = 0)  
      AND (p_channelId is null or  UPPER(b.CHANNEL) = UPPER(p_channelId))
      AND (UPPER(b.POS_POSITION) = UPPER(p_position))
      ORDER BY a.ADVERTISE_PRIORITY ASC; 
END GetBannerEgiftV3;
--
procedure GetSmileGiftVer3(
    p_curPage     in  integer, 
  p_pageSize    in  integer,
  totalRecord   out integer,
  ret out refcur) as
  begin
        open ret for
         select  t.* from ( 
        select t.*,rownum as r from(
         select fnc_getMaxEgiftCashbackById(ev.voucher_id) as cashbackValue, (select p.name from MP_PARTNER p where p.partner_id = evp.partner_id) as partnerName, ev.name, evp.PROMOTION_CONTENT as des,evp.voucher_partner_id as dealId, (select t.IMAGE_PATH from((select IMAGE_PATH from ev_voucher_gallery where voucher_partner_id= evp.voucher_partner_id order by PRIORITY asc))t where rownum=1 )as avatar
        from mp_events_detail med, ev_voucher_partner evp ,ev_voucher ev
        where med.event_id = 1301 and med.detail_id = evp.voucher_partner_id
        and ev.voucher_id = evp.voucher_id)t)  t
    where t.r > ((p_curPage-1)*p_pageSize) and t.r <= (p_curPage*p_pageSize);
  end GetSmileGiftVer3;
--
PROCEDURE GetEGiftBrandV3(
     p_curPage     in  integer, 
    p_pageSize    in  integer,
    totalRecord   out integer,
    ret OUT refcur)as
    begin
        open ret for
        select  t.* from ( 
        select t.*,rownum as r from(
        select x.*,fnc_getMaxEgiftCashbackById(x.voucher_id) as cashbackValue from (select evp.voucher_partner_id as dealId,evp.thumbnail as avatar, v.name, temp.voucher_id from  (select distinct t.voucher_id from
        (select a.*,(select count(0) from EV_ACCEPTED_PARTNER where voucher_id = a.voucher_id) as totalAcceptPartnerEgift  from EV_ACCEPTED_PARTNER a) t
        where t.totalAcceptPartnerEgift=1) temp,ev_voucher v, ev_voucher_partner evp
        where temp.voucher_id = v.voucher_id and  temp.voucher_id = evp.voucher_id and evp.status =2 and v.ORIGINAL_PRICE = 100000  order by temp.voucher_id desc) x )t)  t
    where t.r > ((p_curPage-1)*p_pageSize) and t.r <= (p_curPage*p_pageSize);
    end GetEGiftBrandV3;
--
procedure GetCategoryBrandV3(
    ret out refcur
    )as
    begin
        open ret for
         select t.* from(select distinct vc.category_id,(select category_name from mp_category where category_id = vc.category_id) as category_name
         from EV_ACCEPTED_PARTNER ap,MVIEW_DEAL_VALID_CATEGORY_NEW mdv,EV_Voucher_Category vc,mp_category c
         where ap.voucher_id=mdv.voucher_id  and vc.voucher_id = ap.voucher_id
         and sysdate <= mdv.sell_expired and vc.category_id = c.category_id
        and c.parent_id <> 57
        and mdv.status = 2)t;
    end GetCategoryBrandV3;
--
PROCEDURE GetPartnerEgiftV3(
    ret out refcur
    )as
    begin
         open ret for
            select distinct eap.accepted_partner_id as partnerId,(select company_name from mp_partner where partner_id=eap.accepted_partner_id) as partnerName
           from(
           select t.* from  (select distinct voucher_id from EV_ACCEPTED_PARTNER) t,MVIEW_DEAL_VALID_CATEGORY_NEW mdv
           where t.voucher_id = mdv.voucher_id
           and sysdate <= mdv.sell_expired 
            and mdv.ORIGINAL_PRICE = 100000
             and mdv.status = 2 )t
             , EV_ACCEPTED_PARTNER eap
             where t.voucher_id =  eap.voucher_id ;
    end GetPartnerEgiftV3;
--
PROCEDURE GetTopicV3(
    ret OUT refcur
    )AS
    BEGIN
        OPEN ret FOR
        select TOPIC_ID, TOPIC_NAME, TOPIC_ICON_URL, TOPIC_BANNER_URL
        FROM EV_TOPIC
        WHERE STATUS = 1 ORDER BY PRIORITY;
    END GetTopicV3;
--
PROCEDURE GetLocationV3(
    ret out refcur
    )as
    begin
        open ret for
             select distinct(t.loc_id_root),(select NAME from mp_location where location_id=t.loc_id_root) as location_name
            from (select t.*,sf_getRootLocationId(t.location_id) as loc_id_root
            from (select distinct(map.LOCATION_ID)  from EV_ACCEPTED_PARTNER ap,MP_ACCEPTANCE_POINT map,MVIEW_DEAL_VALID_CATEGORY_NEW mvd
            where ap.accepted_partner_id = map.partner_id and mvd.partner_id = ap.accepted_partner_id and sysdate <= mvd.sell_expired and mvd.status = 2
            and map.status = 1 and map.IS_ACTIVE =1)t)t;
    end GetLocationV3;
--
PROCEDURE GetEgiftCategoryV3(
   p_topicIds IN VARCHAR2,
    p_locationIds IN VARCHAR2,
    p_categoryId  IN VARCHAR2,
    p_partnerIds  IN VARCHAR2,
    p_orderType   IN VARCHAR2,
    p_query       IN VARCHAR2,
    p_pageSize    IN INTEGER,
    p_currPage    IN INTEGER,
    totalRecord   OUT INTEGER,
    ret OUT refcur
    )AS
     l_locationIds VARCHAR2(2000); 
     l_fromRow INTEGER := (p_currPage - 1) * p_pageSize;
     l_toRow   INTEGER := (p_currPage * p_pageSize);
     l_categories VARCHAR2(1000) := sf_getCategories(p_categoryId);
    BEGIN
     IF(p_locationIds!='ALL') THEN
        BEGIN
            l_locationIds:= PKG_WEB_DEAL_NEW.sf_getLocationIds(p_locationIds);
        END;
    ELSE
        BEGIN
            l_locationIds:= 'ALL';
        END;
    END IF;
        open ret for
           SELECT t.voucher_partner_id AS dealId,
             ev.NAME, evp.thumbnail as avatar,
             evp.voucher_price AS salePrice,
             fnc_getMaxEgiftCashbackById(ev.voucher_id) as cashbackValue
        FROM (
              SELECT t.voucher_partner_id
                FROM (
                      SELECT ROWNUM rownumber, t.voucher_partner_id
                        FROM (
                              SELECT voucher_partner_id
                                FROM (
                                       SELECT DISTINCT mdv.voucher_partner_id
                                        ,sf_countSmileGift(mdv.voucher_partner_id) as weight
                                        FROM  MVIEW_DEAL_VALID_CATEGORY_NEW mdv, EV_Voucher_Category evc,
                                        EV_ACCEPTED_PARTNER eap,EV_EGIFT_TOPIC et,MP_ACCEPTANCE_POINT map
--                                            ,EV_VOUCHER_ACCEPTANCE_POINT mapv
                                         WHERE sysdate <= mdv.sell_expired
                                         AND mdv.status = 2
                                          AND mdv.ORIGINAL_PRICE = 100000
                                         AND evc.voucher_id = mdv.voucher_id
                                         AND (l_categories = '0' or (evc.category_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_categories))))
                                         AND evc.VOUCHER_ID = eap.VOUCHER_ID 
                                         AND evc.PARTNER_ID = eap.PARTNER_ID 
                                         AND  mdv.VOUCHER_ID = eap.VOUCHER_ID
                                         AND et.VOUCHER_ID = eap.VOUCHER_ID
                                         AND ((p_partnerIds is null) OR (eap.ACCEPTED_PARTNER_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_partnerIds))))
                                         AND (p_topicIds is null or (et.TOPIC_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_topicIds))))
--                                           AND mapv.partner_id = eap.accepted_partner_id
--                                          AND mapv.acceptance_point_id = map.acceptance_point_id
                                        AND map.partner_id = eap.accepted_partner_id
                                         AND ((l_locationIds = 'ALL') OR (map.location_id in (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_locationIds))))
                                         ORDER BY mdv.voucher_partner_id
                                     )
                              ORDER BY weight DESC
                             ) t
                       WHERE ROWNUM <= l_toRow
                     ) t
               WHERE t.rownumber > l_fromRow
             ) t, EV_Voucher_Partner evp, EV_Voucher ev
       WHERE evp.voucher_partner_id = t.voucher_partner_id
         AND ev.voucher_id = evp.voucher_id;

        SELECT COUNT(DISTINCT mdv.voucher_partner_id) INTO totalRecord
        FROM  MVIEW_DEAL_VALID_CATEGORY_NEW mdv, EV_Voucher_Category evc
        ,EV_ACCEPTED_PARTNER ap,EV_EGIFT_TOPIC et,MP_ACCEPTANCE_POINT map
--         ,EV_VOUCHER_ACCEPTANCE_POINT mapv
        WHERE sysdate <= mdv.sell_expired
                                         AND mdv.status = 2
                                         AND mdv.ORIGINAL_PRICE = 100000
                                         AND evc.voucher_id = mdv.voucher_id
                                         AND (l_categories = '0' or (evc.category_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_categories))))
                                         AND evc.VOUCHER_ID = ap.VOUCHER_ID 
                                         AND evc.PARTNER_ID = ap.PARTNER_ID
                                         AND  mdv.VOUCHER_ID = ap.VOUCHER_ID
                                         AND et.VOUCHER_ID = ap.VOUCHER_ID
                                         AND ((p_partnerIds is null) OR (ap.ACCEPTED_PARTNER_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_partnerIds))))
                                         AND (p_topicIds is null or (et.TOPIC_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_topicIds))))
--                                          AND mapv.partner_id = ap.accepted_partner_id
--                                           AND mapv.acceptance_point_id = map.acceptance_point_id
                                        AND map.partner_id = ap.accepted_partner_id
                                         AND ((l_locationIds = 'ALL') OR (map.location_id in (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_locationIds))));
    END GetEgiftCategoryV3;
--
FUNCTION sf_getCategories (
    p_categoryId IN VARCHAR2
  ) RETURN VARCHAR2 AS
    l_categoryIds VARCHAR2(1000) :='';
  BEGIN 
  
    FOR i IN (
      SELECT category_id
        FROM MP_Category
       WHERE parent_id >= 57
         AND is_active = 1
         AND parent_id IN (
                        SELECT to_number(column_value) 
                          FROM XMLTABLE(p_categoryId))
         OR category_id IN (
                        SELECT to_number(column_value) 
                          FROM XMLTABLE(p_categoryId))    
    ) LOOP 
         l_categoryIds := l_categoryIds || i.category_id || ',';
    END LOOP;
    
    l_categoryIds := SUBSTR(l_categoryIds, 0, LENGTH(l_categoryIds) - 1);
    
    RETURN NVL(l_categoryIds, '0');
  END sf_getCategories;
--
Procedure GetPartnerAcceptancesV3 (
    p_dealId in number,
    retPartners out refcur,
    retAcceptances out refcur
  ) AS
    --ID partner  issue Egift: 21667
    v_partnerId number :=0;
    v_voucherId number :=0;
    v_check number:=0;
    BEGIN
        SELECT PARTNER_ID,VOUCHER_ID  INTO v_partnerId,v_voucherId FROM EV_VOUCHER_PARTNER WHERE VOUCHER_PARTNER_ID = p_dealId;
        IF(v_partnerId<> 21667) THEN
            BEGIN
                open retPartners for select partner_id,company_name as partnerName,egift_cashback_percent as egiftCashback, logo from MP_Partner where partner_id = v_partnerId;
                 OPEN retAcceptances FOR
               select t.*,(select name from mp_location where location_id = t.location_id) as location_name from( SELECT DISTINCT map.partner_id,map.acceptance_point_id, map.point_name, map.address, sf_getRootLocationId(map.location_id)as location_id, map.LATITUDE,map.LONGITUDE
                    FROM MP_Acceptance_Point map, EV_Voucher_Acceptance_Point vap, EV_Voucher_Partner evp
                   WHERE vap.acceptance_point_id = map.acceptance_point_id
                     AND evp.voucher_partner_id = p_dealId
                     AND vap.voucher_id = evp.voucher_id
                     AND vap.partner_id = evp.partner_id
                     and map.status=1) t;
            END;
        ELSE
            BEGIN
              
                select count(0) into v_check from EV_ACCEPTED_PARTNER WHERE voucher_id = v_voucherId AND partner_id = v_partnerId AND ACCEPTED_PARTNER_ID =0;
                if(v_check =0) THEN
                    BEGIN
                         open retPartners for select a.partner_id,a.company_name as partnerName,a.egift_cashback_percent as egiftCashback, logo from MP_Partner a,EV_ACCEPTED_PARTNER b 
                        where a.partner_id = b.ACCEPTED_PARTNER_ID AND b.VOUCHER_ID = v_voucherId AND b.PARTNER_ID = v_partnerID;
                         open retAcceptances for 
                          select t.*,(select name from mp_location where location_id = t.location_id) as location_name from (SELECT DISTINCT map.partner_id,map.acceptance_point_id, map.point_name, map.address, sf_getRootLocationId(map.location_id)as location_id,map.LATITUDE,map.LONGITUDE
                            FROM MP_Acceptance_Point map,EV_ACCEPTED_PARTNER eap
                           WHERE map.partner_id = eap.ACCEPTED_PARTNER_ID
                             AND eap.voucher_id = v_voucherId
                             AND eap.partner_id = v_partnerId
                             AND map.is_active = 1
                             and map.status=1) t;
                    END;
                ELSE
                    BEGIN
                        open retPartners for select a.partner_id,a.company_name as partnerName,a.egift_cashback_percent as egiftCashback from MP_Partner a
                        where a.status = 1 AND a.is_active = 1 AND a.IS_EGIFT =1;
                        open retAcceptances for 
                        select t.*,(select name from mp_location where location_id = t.location_id) as location_name from ( SELECT DISTINCT map.partner_id,map.acceptance_point_id, map.point_name, map.address, sf_getRootLocationId(map.location_id)as location_id,map.LATITUDE,map.LONGITUDE
                            FROM MP_Acceptance_Point map,MP_PARTNER eap
                           WHERE map.partner_id = eap.PARTNER_ID
                            AND eap.status = 1 AND eap.is_active = 1 AND eap.IS_EGIFT =1
                             AND map.is_active = 1
                             and map.status=1) t;
                    END;
                END IF;
            END;
        END IF;
END GetPartnerAcceptancesV3;
--  
PROCEDURE GetPriceEgiftV3(
    p_dealId in number,
    ret out refcur
  )as
  l_accepted_partner_id varchar2(2000) := PKG_EGIFT_V2.sf_getAcceptedPartner(p_dealId);
  l_countPoint number :=0;
  begin
    if (l_accepted_partner_id <> '0') then
        begin
        select t1.count_acc into l_countPoint
        from (select distinct t.voucher_id,(select count(0) from mp_acceptance_point map,EV_ACCEPTED_PARTNER eap  where
        map.partner_id = eap.accepted_partner_id and eap.voucher_id = t.voucher_id) as count_acc
        from (select evp.voucher_id from ev_voucher_partner evp where evp.voucher_partner_id = p_dealId)t,
        EV_ACCEPTED_PARTNER eap,ev_voucher v
        where eap.voucher_id = t.voucher_id 
        and v.voucher_id = t.voucher_id) t1;
       
        open ret for 
           select t2.* from (select t1.*,(select count(0) from mp_acceptance_point map,EV_ACCEPTED_PARTNER eap  where
            map.partner_id = eap.accepted_partner_id and eap.voucher_id = t1.voucher_id) as count_acc
            from (select distinct evp.VOUCHER_PRICE as price,t.voucher_id,evp.voucher_partner_id as dealId,ev.name,evp.title
            from(select voucher_id,accepted_partner_id
            from EV_ACCEPTED_PARTNER where accepted_partner_id IN (
            SELECT to_number(column_value) 
            FROM XMLTABLE(l_accepted_partner_id))) t,ev_voucher ev,ev_voucher_partner evp
            where ev.voucher_id=t.voucher_id and t.voucher_id=evp.voucher_id and evp.status=2 and sysdate <= ev.sell_expired)t1 )t2
        where t2.count_acc = l_countPoint 
        order by t2.price asc;
        end;
    else
        begin
            open ret for
            select evp.VOUCHER_PRICE as price,evp.voucher_partner_id as dealId
            from ev_voucher_partner evp where evp.voucher_partner_id = p_dealId;
        end;
    end if;
END GetPriceEgiftV3;
--
PROCEDURE GetValueCashBackEgiftV3(
    p_dealId in number,
    ret out refcur
    )as 
    begin
    open ret for
       select min(p.egift_cashback_percent) as minCashBackEgift, max(p.egift_cashback_percent) as maxCashBackEgift
       from (select evp.voucher_id from ev_voucher_partner evp
        where evp.voucher_partner_id = p_dealId) t,ev_accepted_partner ap,mp_Partner p
        where t.voucher_id = ap.voucher_id and ap.accepted_partner_id = p.partner_id;
END GetValueCashBackEgiftV3;
--
PROCEDURE GetPostCardInfoV3(p_order_id IN VARCHAR2, ret OUT refcur) 
AS
    v_ORDER_ID NUMBER := 0;
BEGIN
    SELECT ORDER_ID INTO v_ORDER_ID FROM EV_ORDER_POSTCARD WHERE Booking_id = p_order_id;
    OPEN ret FOR SELECT ORDER_ID,
                        POSTCARD_ID,
                        POSTCARD_URL,
                        SENDER_UPLOAD_URL,
                        SENDER_MESSAGE,
                        SENDER_NAME,
                        POSTCARD_STYLE,
                        POSTCARD_MESSAGE,
                        BOOKING_ID, 
                        (SELECT RECEIVE_ID FROM MP_ORDER WHERE ORDER_ID = v_ORDER_ID) RECEIVE_ID
                 FROM EV_ORDER_POSTCARD
                 WHERE Booking_id = p_order_id;
END GetPostCardInfoV3;
--
PROCEDURE GetPartnerLogo (p_partner_id in int,ret out refcur) AS
BEGIN
    OPEN ret FOR SELECT NAME partnerName, LOGO logo, EGIFT_CASHBACK_PERCENT egiftCashback FROM MP_PARTNER WHERE partner_id = p_partner_id;
END GetPartnerLogo;
--
FUNCTION sf_countSmileGift (
    p_dealId IN VARCHAR2
  ) RETURN NUMBER AS
  l_count number := 0;
  BEGIN
    select count(0) into l_count
    from mp_events_detail where event_id = 1301 and detail_id =  p_dealId;
    
    RETURN NVL(l_count, 0);
  END sf_countSmileGift;
--
PROCEDURE GetEgiftCategoryV3_new(
    p_topicIds IN VARCHAR2,
    p_locationIds IN VARCHAR2,
    p_categoryId  IN VARCHAR2,
    p_partnerIds  IN VARCHAR2,
    p_orderType   IN VARCHAR2,
     p_query       IN VARCHAR2,
    p_pageSize    IN INTEGER,
    p_currPage    IN INTEGER,
    totalRecord   OUT INTEGER,
    ret out refcur
)as
    l_locationIds VARCHAR2(2000); 
     l_categories VARCHAR2(1000) := sf_getCategories(p_categoryId);
    BEGIN
     IF(p_locationIds!='ALL') THEN
        BEGIN
            l_locationIds:= PKG_WEB_DEAL_NEW.sf_getLocationIds(p_locationIds);
        END;
    ELSE
        BEGIN
            l_locationIds:= 'ALL';
        END;
    END IF;
    
    OPEN ret FOR
    SELECT t.* FROM (
      SELECT rownum as r, t.*
        FROM (
               SELECT t.voucher_partner_id AS dealId,
             ev.NAME, evp.thumbnail AS avatar,
             evp.voucher_price AS salePrice,
             fnc_getMaxEgiftCashbackById(ev.voucher_id) as cashbackValue 
                        FROM (
                              SELECT voucher_partner_id
                                FROM (
                                       SELECT DISTINCT mdv.voucher_partner_id
                                        ,sf_countSmileGift(mdv.voucher_partner_id) as weight
                                        FROM  MVIEW_DEAL_VALID_CATEGORY_NEW mdv, EV_Voucher_Category evc,
                                        EV_ACCEPTED_PARTNER eap,EV_EGIFT_TOPIC et,MP_ACCEPTANCE_POINT map
                                         WHERE sysdate <= mdv.sell_expired
                                         AND mdv.status = 2
                                          AND mdv.ORIGINAL_PRICE = 100000
                                         AND evc.voucher_id = mdv.voucher_id
                                         AND (l_categories = '0' or (evc.category_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_categories))))
                                         AND evc.VOUCHER_ID = eap.VOUCHER_ID 
                                         AND evc.PARTNER_ID = eap.PARTNER_ID 
                                         AND  mdv.VOUCHER_ID = eap.VOUCHER_ID
                                         AND et.VOUCHER_ID = eap.VOUCHER_ID
                                         AND ((p_partnerIds is null) OR (eap.ACCEPTED_PARTNER_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_partnerIds))))
                                         AND (p_topicIds is null or (et.TOPIC_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_topicIds))))
                                        AND map.partner_id = eap.accepted_partner_id
                                         AND ((l_locationIds = 'ALL') OR (map.location_id in (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_locationIds))))
                                     )
                              ORDER BY weight DESC
                             ) t, EV_Voucher_Partner evp, EV_Voucher ev
       WHERE evp.voucher_partner_id = t.voucher_partner_id
         AND ev.voucher_id = evp.voucher_id)t
             ) t  WHERE t.r > ((p_currPage-1)*p_pageSize) and t.r <= (p_currPage*p_pageSize);
         
        SELECT COUNT(DISTINCT mdv.voucher_partner_id) INTO totalRecord
        FROM  MVIEW_DEAL_VALID_CATEGORY_NEW mdv, EV_Voucher_Category evc
        ,EV_ACCEPTED_PARTNER ap,EV_EGIFT_TOPIC et,MP_ACCEPTANCE_POINT map
        WHERE sysdate <= mdv.sell_expired
                                         AND mdv.status = 2
                                         AND mdv.ORIGINAL_PRICE = 100000
                                         AND evc.voucher_id = mdv.voucher_id
                                         AND (l_categories = '0' or (evc.category_id IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_categories))))
                                         AND evc.VOUCHER_ID = ap.VOUCHER_ID 
                                         AND evc.PARTNER_ID = ap.PARTNER_ID
                                         AND  mdv.VOUCHER_ID = ap.VOUCHER_ID
                                         AND et.VOUCHER_ID = ap.VOUCHER_ID
                                         AND ((p_partnerIds is null) OR (ap.ACCEPTED_PARTNER_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_partnerIds))))
                                         AND (p_topicIds is null or (et.TOPIC_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(p_topicIds))))
                                        AND map.partner_id = ap.accepted_partner_id
                                         AND ((l_locationIds = 'ALL') OR (map.location_id in (SELECT TO_NUMBER(COLUMN_VALUE) FROM XMLTABLE(l_locationIds))));
    end GetEgiftCategoryV3_new;
  
END PKG_EGIFT_V3;

/
