Public Class salestaxadmin
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current(True)


#Region " Public Subs "
    Public Sub checkLogin()
        If IsNothing(Session("loggedin")) Then
            Response.Redirect("login.aspx?returl=" & Request.Url.AbsoluteUri)
        End If
    End Sub
#End Region
    Private Sub loadStates()
        Dim myStates = (From x In db.States Order By x.StateName Ascending).ToList
        'load up the dropdown 
        'need a counter for this
        Dim counter As Integer = 0
        Dim mainListItem As New ListItem("Please Select A State", 0)
        ddlStates.Items.Add(mainListItem)
        For Each ddlstate In myStates
            Dim ddllist As New ListItem(ddlstate.StateName, "chklstStates_" & counter)
            ddlStates.Items.Add(ddllist)
            counter += 1
        Next


        'load up the states checkbox list

        If myStates IsNot Nothing Then
            For Each state In myStates
                Dim ilistitem As New ListItem(state.StateName, state.StateCode)
                If state.StateIsTaxable = 1 Then
                    ilistitem.Selected = True
                End If
                chklstStates.Items.Add(ilistitem)
            Next
        End If



    End Sub
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        checkLogin()

        If IsPostBack Then
            If SaveTaxes() Then
                Response.Redirect("/admin/salestax.aspx?success=true")
            End If
        End If
        loadStates()
    End Sub

    Private Function SaveTaxes() As Boolean

        For Each ilistitem As ListItem In chklstStates.Items
            'lets update the database
            Dim myState = (From x In db.States Where x.StateCode = ilistitem.Value).SingleOrDefault
            If myState IsNot Nothing Then
                If ilistitem.Selected Then
                    myState.StateIsTaxable = 1
                Else
                    myState.StateIsTaxable = 0
                End If
            End If
        Next


        Try
            db.SubmitChanges()
            Return True
        Catch Excep As Exception
            ' If validation fails, store it
            Return False
        End Try


    End Function

End Class