update these 

1- supervisor_trip_screen : 

- image --> sos.png
posistion : x : 340  y : 74
layout : dimensions : w: 44 h : 44
opacity : 100% corner radius : 0

- rectangle 
posistion : x : 221    y : 311
layout : dimensions : w: 168 h : 30
opacity : 100% corner radius : 25
fill : e6e9ed 100%
stroke : 214071 100%
position : inside weight : 2

- text (View Full Map)
posistion : x : 225    y : 316
layout : dimensions : w: 100 h : 22
opacity : 100% corner radius : 0
typography
inter
medium : 15
line height : 22 latter spacing : 0
alignment : center , top
fill : 214071 97%

- image --> attendance.png
posistion : x : 81 y : 495
layout : dimensions : w: 30 h : 30
opacity : 100% corner radius : 0
selection colors : 
2859c5 100%
8fbffa 100%

- frame
position : x : 41 y : 15
layout : flow : freeform
dimensions : w : 339 h : 35
alignment : align bottom left
gap : 98
appearance : opacity : 100% corner radius : 0
selection colors :
2859c5 100%
333333 100%

- image --> navbar_home_homescreen.png
position : x : 41 y : 15
layout : dimensions : w: 32 h : 35
opacity : 100% corner radius : 0
fill : 2859C5 100%

- text (Home)
posistion : x : 38 y : 53
layout : dimensions : w: 34 h : 22
opacity : 100% corner radius : 0
typography
inter
medium : 12
line height : 22 latter spacing : 0
alignment : center , top
fill : 2859C5 54%

- image --> navbar_attendance.png
posistion : x : 171  y : 15
layout : dimensions : w: 35 h : 35
spacing : -8
clip content : check 
opacity : 100% corner radius : 0
fill : ffffff 100%
selecion color : 333333 100%

- text (Attendance)
posistion : x : 155 y : 53
layout : dimensions : w: 67 h : 22
opacity : 100% corner radius : 0
typography
inter
medium : 12
line height : 22 latter spacing : 0
alignment : center , top
fill : 595959 100%

- image --> navbar_profile.png
posistion : x : 4.38  y : 4.38
layout : dimensions : w: 26.25 h : 26.25
clip content : check 
opacity : 100% corner radius : 0
fill : 333333 100%

- text (Profile)
posistion : x : 303 y : 53
layout : dimensions : w: 37 h : 22
opacity : 100% corner radius : 0
typography
inter
medium : 12
line height : 22 latter spacing : 0
alignment : center , top
fill : 595959 100%

----------------------------------

2- supervisor_attendance_screen : 

- image --> sos.png
posistion : x : 345  y : 79
layout : dimensions : w: 44 h : 44
clip content : check 
opacity : 100% corner radius : 0
fill : ffffff 100%
selection colors : 
333333 100%

- image --> check.png
posistion : x : 40   y : 573
layout : dimensions : w: 54 h : 24
typography
inter
semi bold : 24
line height : 24 latter spacing : 0
alignment : center , top
fill : 000000 100%

- image --> 13.png
posistion : x : 42   y : 123
layout : dimensions : w: 24 h : 24
appearance 
opacity : 100% corner radius : 50

- text (Welcome, supervisor name)
posistion : x : 82     y : 124
layout : dimensions : w: 125 h : 22
opacity : 100% corner radius : 0
typography
inter
semi bold : 20
line height : 22 latter spacing : 0
alignment : center , top
fill : ffffff 100%

- text (Bus #7)
posistion : x : 82     y : 152
layout : dimensions : w: 66 h : 22
opacity : 100% corner radius : 0
typography
inter
semi bold : 20
line height : 22 latter spacing : 0
alignment : center , top
fill : ffffff 100%

- rectangle 
posistion : x : 15    y : 549
layout : dimensions : w: 355 h : 154
opacity : 100% corner radius : 30
fill : ffffff 37%
stroke : ffffff 100%
position : inside weight : 1
effects :
drop shadow : position : 
x : 0 y : 4 blure : 4 spread : 0 color : 000000 25%
background blur : uniform blure : 30 

- rectangle 
posistion : x : 30     y : 680
layout : dimensions : w: 148 h : 46
opacity : 100% corner radius : 7
fill : e6e9ed 94%
stroke : 214071 100%
position : inside weight : 1

- text (Rescan)
posistion : x : 47     y : 691
layout : dimensions : w: 80 h : 20
opacity : 100% corner radius : 0
typography
inter
medium : 20
line height : 22 latter spacing : 0
alignment : center , top
fill : 000000 100%

- image --> 15.png
posistion : x : 136   y : 686
layout : dimensions : w: 31 h : 31
clip content : check
appearance 
opacity : 100% corner radius : 50
selection color : 214071 92%

- image --> navbar_home.png
layout : dimensions : w: 32 h : 35
opacity : 100% corner radius : 0
fill : 000000 100%

- image --> navbar_attendance_homescreen.png
posistion : x : 130 y : 0
layout : dimensions : w: 35 h : 35
spacing : -8
clip content : check 
opacity : 100% corner radius : 0
fill : ffffff 100%
selecion color : 2859c5 100%

- image --> navbar_profile.png
posistion : x : 263  y : 0
layout : dimensions : w: 35 h : 35
clip content : check 
opacity : 100% corner radius : 0
fill : ffffff 100%
selection colors : 
333333 100%

----------------------------------
3- role_selecetion_screen

- image --> supervisor.png
posistion : x : 138  y : 267
layout : dimensions : w: 114 h : 97
opacity : 100% corner radius : 50
fill : ffffff 100%

- rectangle 
posistion : x : 50     y : 316
layout : dimensions : w: 291 h : 132
opacity : 100% corner radius : 15
fill : ffffff 32%
stroke : ffffff 79%
position : inside weight : 1

- rectangle 
posistion : x : 84     y : 391
layout : dimensions : w: 223 h : 43
opacity : 100% corner radius : 33
fill : linear 45%
stops : 0% left : ffffff 100%
stops : 100% right : 3f79d7 100%

- text (Supervisor)
posistion : x : 128    y : 398
layout : dimensions : w: 130 h : 29
opacity : 100% corner radius : 0
typography
inter
bold : 24
line height : 22 latter spacing : 0
alignment : center , top
fill : ffffff 100%

- chevron_backward
position x : 262  y : 396
rotation : 180
resizing : w : 33 h : 33
clip content : check
alignment : center
opacity : 100% corner radius : 0
fill : ffffff 100%

- image --> parent.png
posistion : x : 138  y : 494
layout : dimensions : w: 114 h : 97
opacity : 100% corner radius : 50
fill : ffffff 100%

- rectangle 
posistion : x : 45     y : 543
layout : dimensions : w: 291 h : 132
opacity : 100% corner radius : 15
fill : ffffff 32%
stroke : ffffff 79%
position : inside weight : 1

- rectangle 
posistion : x : 84     y : 391
layout : dimensions : w: 223 h : 43
opacity : 100% corner radius : 33
fill : linear 45%
stops : 0% left : ffffff 100%
stops : 100% right : 3f79d7 100%

- text (Parent)
posistion : x : 152 y : 620
layout : dimensions : w: 94 h : 17
opacity : 100% corner radius : 0
typography
inter
bold : 24
line height : 22 latter spacing : 0
alignment : center , top
fill : 000000 100%

- chevron_backward
position x : 258  y : 619
rotation : 180
resizing : w :  33 h : 33
alignment : center
opacity : 100% corner radius : 0
fill : ffffff 100%
----------------------------------
4- i need to change the color of the button into 
fill : linear 97%
from left : stops : 0% 214071 100%
from right : stops : 100% 3f79d7 100%
in these screens :

onboarding_screen_two/onboarding_screen_three --> (Next)
onboarding_screen_four --> (Get Started)
supervisor_login_screen --> (Log In)
supervisor_forget_password_screen --> (Get OTP)
supervisor_otp_screen --> (Reset Password)
supervisor_reset_password_screen --> (Create New Password)
parent_login_screen --> (Log In)
parent_signup_info_screen --> (Countinue)
parent_signup_student_screen --> (Sign Up)
parent_forget_password_screen --> (Get OTP)
parent_otp_screen --> (Reset Password)
parent_reset_password_screen --> (Create New Password)
supervisor_home_screen --> (Start Trip)
supervisor_qr_confirmation_screen --> (Done)
supervisor_attendance_screen --> (Confirm)
supervisor_trip_screen --> (take attendance)

----------------------------------
