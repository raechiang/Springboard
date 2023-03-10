/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you:
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1.

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface.
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

NOTE: Slack member FrankF [peer mentor / alum]:
MySQL has a slightly different syntax - so you need to be aware of that.  The
new server is still pinned in this channel ... but the original is not accessible
from slack because we are limited to 90 days of history.
I'll try to create a FAQ Notion, and we can pin it here for future reference.
In the meantime, the backup server is: frankfletcher.co/springboard_phpmyadmin
The popup username/password is:
username: student
password: springboardbackup
The phpmyadmin username/password is:
username: admin_springboard
password: springboardbackup
The relevant database is named "admin_springboard"

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name
FROM Facilities
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
/* 5 Facilities do not charge a fee to members. We can also use COUNT in the
SELECT clause. */

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost < (0.2 * monthlymaintenance);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
FROM Facilities
WHERE facid BETWEEN 1 AND 5;

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance,
    CASE WHEN monthlymaintenance < 100 THEN 'cheap'
      ELSE 'expensive'
      END maintenance_label
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT surname, firstname, joindate
FROM Members
WHERE joindate IN
	(SELECT MAX(joindate) FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT CONCAT(firstname, ' ', surname) AS fullname, TennisBookings.name
FROM Members
INNER JOIN (
    SELECT Facilities.name, Bookings.memid
    FROM Bookings
    INNER JOIN Facilities
    ON Bookings.facid = Facilities.facid
    WHERE Bookings.facid IN (0, 1) -- Tennis Court 1 and 2 facid's
) AS TennisBookings
ON Members.memid = TennisBookings.memid
GROUP BY Members.memid, fullname, TennisBookings.name
ORDER BY fullname, TennisBookings.name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT Facilities.name AS facility,
    CASE WHEN (Bookings.memid = 0) THEN (Bookings.slots * Facilities.guestcost)
        ELSE (Bookings.slots * Facilities.membercost)
        END cost,
    CONCAT(Members.firstname, ' ', Members.surname) AS fullname
FROM Bookings
LEFT JOIN Facilities
ON Bookings.facid = Facilities.facid
LEFT JOIN Members
ON Bookings.memid = Members.memid
WHERE starttime LIKE '2012-09-14%'
AND (
    CASE WHEN (Bookings.memid = 0) THEN ((Bookings.slots * Facilities.guestcost) > 30)
        ELSE ((Bookings.slots * Facilities.membercost) > 30)
        END
)
ORDER BY cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT ExpensiveBookings.facility, ExpensiveBookings.cost, CONCAT(firstname, ' ', surname) AS fullname
FROM Members
RIGHT JOIN (
    SELECT Facilities.name AS facility, Bookings.memid AS memid,
        CASE WHEN (Bookings.memid = 0) THEN (Bookings.slots * Facilities.guestcost)
            ELSE (Bookings.slots * Facilities.membercost)
            END cost
    FROM Bookings
    LEFT JOIN Facilities
    ON Bookings.facid = Facilities.facid
    WHERE starttime LIKE '2012-09-14%'
    AND (
        CASE WHEN (Bookings.memid = 0) THEN ((Bookings.slots * Facilities.guestcost) > 30)
            ELSE ((Bookings.slots * Facilities.membercost) > 30)
            END)
    ) AS ExpensiveBookings
ON Members.memid = ExpensiveBookings.memid
ORDER BY ExpensiveBookings.cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook
for the following questions.

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT Facilities.name AS facility_name,
    SUM(CASE WHEN (Bookings.memid = 0) THEN (Bookings.slots * Facilities.guestcost)
    	ELSE (Bookings.slots * Facilities.membercost)
    	END) AS revenue
FROM Bookings
LEFT JOIN Facilities
ON Bookings.facid = Facilities.facid
GROUP BY Facilities.name
HAVING revenue < 1000
ORDER BY revenue;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT m1.surname, m1.firstname, m2.surname AS rec_by_surname, m2.firstname AS rec_by_firstname
FROM Members AS m1
INNER JOIN Members as m2
ON m1.recommendedby = m2.memid
-- WHERE m1.recommendedby <> 0 -- Include this in MyPHPAdmin for the same results as in the notebook
ORDER BY m1.surname, m1.firstname;

/* Q12: Find the facilities with their usage by member, but not guests */
-- How many times facility was used by a member?
SELECT Facilities.name, COUNT(memid) AS uses_by_member
FROM Bookings
LEFT JOIN Facilities
ON Bookings.facid = Facilities.facid
WHERE memid <> 0
GROUP BY Bookings.facid, Facilities.name
ORDER BY Bookings.facid;

/* Q13: Find the facilities usage by month, but not guests */
-- How many times a facility was used per month, disregarding membership status?
-- Booking earliest date is 2012-07-03 08:00:00
-- Booking latest date is 2012-09-30 19:30:00
SELECT Facilities.name AS facility_name,
    CASE WHEN (Bookings.starttime LIKE '2012-07%') THEN 'July'
    WHEN (Bookings.starttime LIKE '2012-08%') THEN 'August'
    WHEN (Bookings.starttime LIKE '2012-09%') THEN 'September' END AS month,
    COUNT(bookid) AS total_books
FROM Bookings
RIGHT JOIN Facilities
ON Bookings.facid = Facilities.facid
GROUP BY facility_name, month;
-- How many times a facility was used per month, excluding guests?
SELECT Facilities.name AS facility_name,
    CASE WHEN (Bookings.starttime LIKE '2012-07%') THEN 'July'
    WHEN (Bookings.starttime LIKE '2012-08%') THEN 'August'
    WHEN (Bookings.starttime LIKE '2012-09%') THEN 'September' END AS month,
    COUNT(bookid) AS total_books
FROM Bookings
RIGHT JOIN Facilities
ON Bookings.facid = Facilities.facid
WHERE Bookings.memid <> 0
GROUP BY facility_name, month;
