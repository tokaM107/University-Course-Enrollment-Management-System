from flask import Flask, render_template, request, flash, redirect, url_for, session, make_response
from decouple import config
import pyodbc
import time

app = Flask(__name__)
app.secret_key = 'supersecretkey'

def get_db_connection():
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={config('DB_SERVER')};"
        f"DATABASE={config('DB_DATABASE')};"
        f"Trusted_Connection=yes;"
    )
    return pyodbc.connect(conn_str, autocommit=False)

@app.after_request
def add_header(response):
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
    return response

@app.route('/')
def index():
    if not session.get('user_id'):
        return redirect(url_for('enroll'))
    return render_template('index.html')

@app.route('/logout')
def logout():
    session.pop('user_id', None)
    session.pop('is_admin', None)
    return redirect(url_for('enroll'))

@app.route('/enroll', methods=['GET', 'POST'])
def enroll():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT 
                co.OfferingID, 
                co.CourseID, 
                co.InstructorID, 
                co.MaxCapacity, 
                co.CurrentEnrollment,
                (co.MaxCapacity - co.CurrentEnrollment) AS SeatsAvailable,
                co.Price
            FROM CourseOfferings co
        """)
        offerings = cursor.fetchall()

        if request.method == 'POST':
            user_id = request.form.get('user_id')
            if not session.get('user_id'):
                cursor.execute("SELECT StudentID FROM Students WHERE StudentID = ?", (user_id,))
                student = cursor.fetchone()
                if student:
                    session['user_id'] = user_id
                    session['is_admin'] = False
                else:
                    cursor.execute("SELECT 1 FROM Admins WHERE AdminID = ?", (user_id,))
                    admin = cursor.fetchone()
                    if admin:
                        session['user_id'] = user_id
                        session['is_admin'] = True
                    else:
                        flash("Invalid ID", "error")
                        return render_template('enroll.html', offerings=offerings)
                return redirect(url_for('enroll'))
            else:
                if session.get('is_admin'):
                    first_name = request.form['first_name']
                    last_name = request.form['last_name']
                    initial_balance_str = request.form['initial_balance']
                    offering_id = int(request.form['offering_id'])

                    try:
                        initial_balance = float(initial_balance_str)
                        if initial_balance < 0 or initial_balance > 999999.99:
                            raise ValueError("Initial balance must be between 0 and 999999.99")
                    except ValueError as e:
                        flash(f"Invalid initial balance: {str(e)}", "error")
                        return render_template('enroll.html', offerings=offerings, is_admin=True)

                    unique_email = f"{first_name.lower()}.{last_name.lower()}.{int(time.time())}@example.com"
                    try:
                        cursor.execute("{CALL sp_CreateAndEnrollStudent (?, ?, ?, ?, ?, ?, ?, ?)}", 
                                       (first_name, last_name, initial_balance, offering_id,
                                        unique_email, '2000-01-01', 1, 1))
                        result = cursor.fetchone()
                        if result:
                            conn.commit()
                            flash("Student created and enrolled successfully!", "success")
                        else:
                            conn.rollback()
                            flash("Procedure executed but returned no result.", "error")
                    except Exception as e:
                        conn.rollback()
                        flash(f"Enrollment failed: {str(e)}", "error")
                    return redirect(url_for('enroll'))
                else:
                    student_id = session.get('user_id')
                    offering_id = int(request.form['offering_id'])
                    cursor.execute("""
                        SELECT COUNT(*) 
                        FROM Enrollments e
                        JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
                        WHERE e.StudentID = ? AND co.CourseID = (
                            SELECT CourseID FROM CourseOfferings WHERE OfferingID = ?
                        )
                    """, (student_id, offering_id))
                    if cursor.fetchone()[0] > 0:
                        flash("Already enrolled in this course.", "error")
                        return redirect(url_for('enroll'))

                    cursor.execute("SELECT Balance FROM Students WHERE StudentID = ?", (student_id,))
                    balance = cursor.fetchone()[0]
                    cursor.execute("SELECT Price, (MaxCapacity - CurrentEnrollment) AS SeatsAvailable FROM CourseOfferings WHERE OfferingID = ?", (offering_id,))
                    price, seats_available = cursor.fetchone()

                    if balance < price:
                        flash(f"Insufficient balance. Required: {price}, Available: {balance}", "error")
                        return redirect(url_for('enroll'))
                    if seats_available <= 0:
                        flash("No seats available for this course.", "error")
                        return redirect(url_for('enroll'))

                    try:
                        cursor.execute("INSERT INTO Enrollments (StudentID, OfferingID) VALUES (?, ?)", (student_id, offering_id))
                        cursor.execute("UPDATE CourseOfferings SET CurrentEnrollment = CurrentEnrollment + 1 WHERE OfferingID = ?", (offering_id,))
                        cursor.execute("UPDATE Students SET Balance = Balance - ? WHERE StudentID = ?", (price, student_id))
                        conn.commit()
                        flash("Enrollment successful!", "success")
                    except Exception as e:
                        flash(f"Enrollment failed: {str(e)}", "error")
                        conn.rollback()
                    return redirect(url_for('enroll'))

        if session.get('user_id'):
            if session.get('is_admin'):
                return render_template('enroll.html', offerings=offerings, is_admin=True)
            else:
                student_id = session.get('user_id')
                cursor.execute("SELECT Balance FROM Students WHERE StudentID = ?", (student_id,))
                balance = cursor.fetchone()[0]
                cursor.execute("""
                    SELECT e.EnrollmentID, co.OfferingID, co.CourseID
                    FROM Enrollments e
                    JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
                    WHERE e.StudentID = ?
                """, (student_id,))
                enrollments = cursor.fetchall()
                return render_template('enroll.html', offerings=offerings, is_admin=False, balance=balance, enrollments=enrollments)
        return render_template('enroll.html', offerings=offerings)
    except Exception as e:
        flash(f"Error loading enrollment form: {str(e)}", "error")
        return render_template('enroll.html', offerings=[])
    finally:
        cursor.close()
        conn.close()

@app.route('/courses')
def courses():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                co.OfferingID, 
                co.CourseID, 
                co.InstructorID, 
                co.MaxCapacity, 
                co.CurrentEnrollment,
                co.Price,
                (co.MaxCapacity - co.CurrentEnrollment) AS SeatsAvailable
            FROM CourseOfferings co
        """)
        courses = cursor.fetchall()
        conn.close()
        return render_template('courses.html', courses=courses)
    except Exception as e:
        flash(f"Error fetching courses: {str(e)}", "error")
        return render_template('courses.html', courses=[])

@app.route('/balance/<int:student_id>')
def balance(student_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT FirstName, LastName, Balance FROM Students WHERE StudentID = ?", (student_id,))
        student = cursor.fetchone()
        if not student:
            flash(f"Student with ID {student_id} not found in database", "error")
            return redirect(url_for('index'))
        cursor.execute("""
            SELECT e.EnrollmentID, e.OfferingID, e.EnrollmentStatus
            FROM Enrollments e
            WHERE e.StudentID = ?
        """, (student_id,))
        enrollments = cursor.fetchall()
        conn.close()
        return render_template('balance.html', student=student, enrollments=enrollments, student_id=student_id)
    except pyodbc.Error as e:
        flash(f"Database error fetching student balance: {str(e)}", "error")
        return redirect(url_for('index'))
    except Exception as e:
        flash(f"Unexpected error fetching student balance: {str(e)}", "error")
        return redirect(url_for('index'))

@app.route('/student_progress')
def student_progress():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT StudentID, FirstName, LastName, TotalCourses FROM vw_StudentProgress")
        students = cursor.fetchall()
        conn.close()
        return render_template('student_progress.html', students=students)
    except Exception as e:
        flash(f"Error fetching student progress: {str(e)}", "error")
        return render_template('student_progress.html', students=[])

if __name__ == '__main__':
    app.run(debug=True)