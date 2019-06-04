  SELECT   DISTINCT i.REGISTRATIONID AS CASE,
                    i.CREATED AS CREATED,
                    i.TITLE AS ISSUE_TITLE,
                    app.APPLICATIONGROUP AS APPGROUP,
                    app.NAME AS APPLICATION,
                    co.NAME AS COMPANY,
                    org.NAME AS ORGANIZATION,
                    bu.NAME AS BUSINESSEVENT_UNIT,
                    class.NAME AS CLASSIFICATION,
                    CONVERT (status.ISSUESTATENEW, 'US7ASCII') AS ACTIVITY,
                    status.MODIFIEDDATE AS TIMESTAMP,
                    last_status_equals_case_closed.ACTIVITY AS END_ACTIVITY,
                    usr.NAME AS "RESOURCE"
    FROM                              KASPERSK.ISSUE i
                                   LEFT JOIN
                                      KASPERSK.BUSINESSUNIT bu
                                   ON bu.OID = i.BUSINESSUNIT
                                LEFT JOIN
                                   KASPERSK.COMPANY co
                                ON co.OID = bu.COMPANY
                             LEFT JOIN
                                KASPERSK.ORGANIZATION org
                             ON org.OID = i.ORGANIZATION
                          LEFT JOIN
                             KASPERSK.CLASSIFICATION class
                          ON class.OID = i.CLASSIFICATION
                       INNER JOIN
                          KASPERSK.ISSUEISSUES_APPLICATI_BF90650B issueapp
                       ON issueapp.issues = i.oid
                    INNER JOIN
                       KASPERSK.application app
                    ON app.oid = issueapp.applications
                 INNER JOIN
                    KASPERSK.ISSUESTATUSLOG status
                 ON status.ISSUE = i.OID
              INNER JOIN
                 KASPERSK.PERMISSIONPOLICYUSER usr
              ON usr.oid = status."USER"
           INNER JOIN
              (SELECT   status.ISSUE,
                        status.MODIFIEDDATE AS TIMESTAMP,
                        status.ISSUESTATENEW AS ACTIVITY
                 FROM      KASPERSK.ISSUESTATUSLOG status
                        INNER JOIN
                           KASPERSK.ISSUESTATUSLOG case_closed
                        ON case_closed.OID = status.OID
                           AND REGEXP_LIKE (
                                 case_closed.ISSUESTATENEW,
                                 '^#01.*|^#29.*|^20.*|^22.*|^24.*|^H08.*|^H14.*|^H10.*|^H11.*|^H09.*|^H12.*|^H13.*'
                              )
                WHERE   status.MODIFIEDDATE =
                           (SELECT   MAX (statusLast.MODIFIEDDATE)
                              FROM   KASPERSK.ISSUESTATUSLOG statusLast
                             WHERE   statusLast.ISSUE = status.ISSUE))
              last_status_equals_case_closed
           ON last_status_equals_case_closed.ISSUE = i.OID
ORDER BY   i.REGISTRATIONID, status.MODIFIEDDATE