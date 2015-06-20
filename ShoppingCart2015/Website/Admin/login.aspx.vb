Public Class WebForm1
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current()

#Region " Page Summary "
    ''' <summary>
    ''' this is the login/logout page, we are going to pull all the users from the users table and verify their
    ''' login information.
    ''' 
    ''' to logout pass the following querystring to this page: action=logout
    ''' 
    ''' The following sessions are set here :
    ''' 
    ''' UserID
    ''' Username
    ''' loggedin
    ''' accesslevel
    ''' 
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
#End Region

#Region " LINQ Properties "
    Public ReadOnly Property oUsers As List(Of DataClasses.User)
        Get
            Dim myUsers = (From x In db.Users Where x.Status = "Active").ToList
            If myUsers IsNot Nothing Then
                Return myUsers
            Else
                Return Nothing
            End If
        End Get
    End Property
#End Region

#Region " Button Events "
    Private Sub btnLogin_Click(sender As Object, e As EventArgs) Handles btnLogin.Click
        Dim sEnteredUsername As String = txtUserName.Text.Trim
        Dim sEnteredPassword As String = txtPassword.Text.Trim

        If oUsers.Any(Function(x) x.Username.Contains(sEnteredUsername)) Then
            'username is valid lets check password
            If oUsers.Any(Function(x) x.Password = sEnteredPassword) Then
                'password is valid, lets log them in
                Dim myUser = (From x In oUsers Where x.Username = sEnteredUsername AndAlso x.Password = sEnteredPassword).SingleOrDefault
                Session("userID") = myUser.UserID
                Session("Username") = myUser.Username
                Session("loggedin") = "Yes"
                Session("AccessLevel") = myUser.AccessLevel
                If Request("returl") <> "" Then
                    Response.Redirect(Request("returl"))
                Else
                    Response.Redirect("default.aspx")
                End If
            Else
                'password is invalid
                lblFeedback.Text = "Invalid Password"
                phFeedBack.Visible = True
            End If
        Else
            'username is invalid
            lblFeedback.Text = "Invalid Username"
            phFeedBack.Visible = True
        End If
    End Sub

#End Region

#Region " Loading "
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        checkUserStatus()
        txtUserName.Focus()
    End Sub

#End Region

#Region " Public Subs "
    Public Sub checkUserStatus()
        If Session("LoggedIn") = "Yes" Then
            'user is logged in, lets see if they want to log out
            If Request("action") = "logout" Then
                'log the user out
                Session.Remove("loggedin")
                Response.Redirect("login.aspx")
            Else
                'send them where they were meant to go
                If Request("returl") <> "" Then
                    Response.Redirect(Request("returl"))
                Else
                    Response.Redirect("default.aspx")
                End If
            End If
        Else

        End If

    End Sub

#End Region


End Class