''' <summary>
''' These functions are used as the confirmation screen when deleting items from the sales manager
''' available actions:
''' 
''' deletecategory
''' 
''' 
''' </summary>
''' <remarks>
'''</remarks>
Public Class adminActions
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current(True)

#Region " Linq Properties "
    Public ReadOnly Property ObjectID As Integer
        Get
            If Request("id") IsNot Nothing AndAlso IsNumeric(Request("id")) Then
                Return CInt(Request("id"))
            Else
                Return Nothing
            End If
        End Get
    End Property
    Public ReadOnly Property Action As String
        Get
            If Request("action") IsNot Nothing Then
                Return Request("action")
            Else
                Return Nothing
            End If
        End Get
    End Property
#End Region

#Region " Public Subs "
    Public Sub checkLogin()
        If IsNothing(Session("loggedin")) Then
            Response.Redirect("login.aspx?returl=" & Request.Url.AbsoluteUri)
        End If
    End Sub

    Public Sub loadAction()
        Select Case Action.ToLower
            'here we are going to get what action to run
            Case "deletecategory"
                'lets load up the category we need to delete
                loadCategory()
            Case Else
                'there was an invalid action passed, lets hide everything but cancel
                phActionNotValid.Visible = True
                phActions.Visible = False
                btnConfirm.Visible = False
                lblError.Text = "Invalid action, cannot continue."
        End Select

    End Sub
#End Region
#Region " Action Loading Subs "
    Public Sub loadCategory()
        Dim myCategory As DataClasses.Category = (From x In db.Categories Where x.CategoryID = ObjectID).SingleOrDefault
        If myCategory IsNot Nothing Then
            'this is a valid category, lets display 
            lblAction.Text = "Delete"
            lblItemType.Text = "Category"
            lblItemName.Text = myCategory.CategoryName
        Else
            'this category does not exist, lets show the error
            phActionNotValid.Visible = True
            phActions.Visible = False
            btnConfirm.Visible = False
            lblError.Text = "Invalid Category ID, cannot continue.<br />"

        End If
    End Sub
#End Region
#Region " Action Deleting Subs"
    Protected Sub DeleteCategory()

        Dim myCategory As DataClasses.Category = (From c In db.Categories Where c.CategoryID = ObjectID).SingleOrDefault

        '////////////////////////////////////////////////////////////////////////////
        '//
        '// lets move all the products out of this category before we delete it
        '//
        '////////////////////////////////////////////////////////////////////////////
        If myCategory IsNot Nothing Then
            Dim myProducts = (From p In db.Products Where p.CategoryID = myCategory.CategoryID).ToList
            'lets get the category id of "uncategorized"
            Dim uncategorized As DataClasses.Category = (From c In db.Categories Where c.CategoryName.ToLower = "uncategorized").FirstOrDefault
            If uncategorized Is Nothing Then
                'there is no uncategorized category, lets create it
                Dim NewCat As New DataClasses.Category
                With NewCat
                    .ParentID = Nothing
                    .CategoryName = "Uncategorized"
                    .Status = "Active"
                    .DateCreated = Now
                    .DateModified = Now
                End With
                db.Categories.InsertOnSubmit(NewCat)
                db.SubmitChanges()
                'the new category was created now lets assign it
                uncategorized = NewCat
            End If
            If myProducts IsNot Nothing Then
                For Each P As DataClasses.Product In myProducts
                    'let update this product category to uncategorized
                    Dim myProduct = (From x In db.Products Where x.ProductID = P.ProductID).SingleOrDefault
                    With myProduct
                        .CategoryID = uncategorized.CategoryID
                    End With
                    db.SubmitChanges()
                Next
            End If
            '////////////////////////////////////////////////////////////////////////////
            'all the products are now moved, lets delete the category now
            myCategory.Status = "Deleted"
            myCategory.DateModified = Now
            db.SubmitChanges()
            Response.Redirect(Request("returl"))
        End If
    End Sub

#End Region

    Private Sub btnConfirm_Click(sender As Object, e As EventArgs) Handles btnConfirm.Click
        If Not IsNothing(ObjectID) Then
            Select Case Action.ToLower
                'here we are going to get what action to run
                Case "deletecategory"
                    'lets load up the category we need to delete
                    DeleteCategory()
                Case Else
                    'there was an invalid action passed, lets hide everything but cancel
                    phActionNotValid.Visible = True
                    phActions.Visible = False
                    btnConfirm.Visible = False
                    lblError.Text = "Invalid action, cannot continue."
            End Select
        Else
            'the id passed in is invalid, lets stop here
            phActionNotValid.Visible = True
            phActions.Visible = False
            btnConfirm.Visible = False
            lblError.Text = "Invalid ID, cannot continue."
        End If
    End Sub

    Private Sub adminActions_Load(sender As Object, e As EventArgs) Handles Me.Load
        checkLogin()

        If Action IsNot Nothing Then
            loadAction()
        Else
            'there was an invalid action passed, lets hide everything but cancel
            phActionNotValid.Visible = True
            phActions.Visible = False
            btnConfirm.Visible = False
            lblError.Text = "Invalid action, cannot continue."

        End If

    End Sub

End Class