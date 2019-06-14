 SELECT   DISTINCT i.REGISTRATIONID AS CASE,
                     i.CREATED AS CREATED,
                     i.TITLE AS ISSUE_TITLE,
                     I.APPLICATIONLIST AS application,
                     application_group.application_group_concat,
                     co.NAME AS COMPANY,
                     org.NAME AS ORGANIZATION,
                     bu.NAME AS BUSINESSEVENT_UNIT,
                     class.NAME AS CLASSIFICATION,
                     CONVERT (status.ISSUESTATENEW, 'US7ASCII') AS ACTIVITY,
                     status.MODIFIEDDATE AS TIMESTAMP,
                     last_status_equals_case_closed.ACTIVITY AS END_ACTIVITY,
                     usr.NAME AS "RESOURCE",
                     ts_total_hours.HOURS AS "TS_TOTAL_HOURS",
                     worktimesheet_hours.HOURS AS "WTS_TOTAL_HOURS"
     FROM                                       KASPERSK.ISSUE i
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
                                     (            /* get date of end status */
                                      SELECT   MAX (statusLast.MODIFIEDDATE)
                                        FROM   KASPERSK.ISSUESTATUSLOG statusLast
                                       WHERE   statusLast.ISSUE =
                                                  status.ISSUE))
                        last_status_equals_case_closed
                     ON last_status_equals_case_closed.ISSUE = i.OID
                  LEFT JOIN
                     (  SELECT   ts.ISSUE,
                                 SUM(  ts.monday
                                     + ts.tuesday
                                     + ts.WEDNESDAY
                                     + ts.THURSDAY
                                     + ts.FRIDAY
                                     + ts.SATURDAY
                                     + ts.SUNDAY)
                                    AS HOURS
                          /*wt."START",
                          wt."END",
                          u.NAME*/
                          FROM         KASPERSK.timesheet ts
                                    INNER JOIN
                                       KASPERSK.worktime wt
                                    ON wt.timesheet = ts.oid
                                 INNER JOIN
                                    KASPERSK.PERMISSIONPOLICYUSER u
                                 ON u.oid = ts.OWNER
                      GROUP BY   ts.ISSUE) ts_total_hours
                  ON ts_total_hours.issue = i.oid
               LEFT JOIN
                  (  SELECT   wts.issue, SUM (wts.hours) AS hours
                       FROM   KASPERSK.worktimesheet wts
                   GROUP BY   wts.issue) worktimesheet_hours
               ON worktimesheet_hours.issue = i.oid
            INNER JOIN
               (  SELECT   distappgroup.issues,
                           LISTAGG (
                              distappgroup.applicationgroup,
                              ','
                           )
                              WITHIN GROUP (ORDER BY
                                               distappgroup.applicationgroup)
                              AS application_group_concat
                    FROM   (  SELECT   DISTINCT
                                       issueapp.issues, app.applicationgroup
                                FROM      KASPERSK.ISSUEISSUES_APPLICATI_BF90650B issueapp
                                       INNER JOIN
                                          KASPERSK.application app
                                       ON app.oid = issueapp.applications
                            ORDER BY   issueapp.issues) distappgroup
                GROUP BY   distappgroup.issues) application_group
            ON application_group.issues = i.oid