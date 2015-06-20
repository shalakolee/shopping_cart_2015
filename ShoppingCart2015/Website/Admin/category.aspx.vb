''' <summary>
''' TODO: make this category be able to have multiple parent categories
''' going to do this the same way as the products in multiple categories
''' </summary>
''' <remarks></remarks>

Public Class adminCategory
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current(True)

    Private myCategoryList As New List(Of DataClasses.Category)

#Region " Linq Properties "
    Public ReadOnly Property CategoryID
        'not declaring this as an integer so that we can check for *nothing
        Get
            If Request("id") IsNot Nothing AndAlso IsNumeric(Request("id")) Then
                Return CInt(Request("id"))
            Else
                Return Nothing
            End If
        End Get
    End Property
    Public ReadOnly Property oCategory As DataClasses.Category
        Get
            If CategoryID IsNot Nothing Then
                'category is a valid numeric value
                Dim thisCategory As DataClasses.Category = (From c In db.Categories Where c.CategoryID = CInt(CategoryID)).SingleOrDefault
                If thisCategory IsNot Nothing Then
                    'return the category
                    Return thisCategory
                Else
                    'category does not exist
                    Return Nothing
                End If
            Else
                Return Nothing
            End If
        End Get
    End Property


#End Region
#Region " Parent Category Listings "
    ''' <summary>
    ''' Great way to list a flat table with linq
    ''' </summary>
    ''' <remarks>
    ''' thanks brendon for the help!
    ''' Usage:
    ''' The global declaration is a must here so that we have a unified list
    ''' Global declaration: Private myCategoryList As New List(Of DataClasses.Category)
    ''' 
    ''' </remarks>

    Function createCategoryTree(Optional ByVal catID = Nothing, Optional ByVal level = 0)

        'need to use a new data context here so that its not overwriting the values from the original
        'not updateable because we are just using this as a temp item
        Dim db1 As DataContext = DataContext.Current()

        'only going to filter out deleted items here


        'parent category
        Dim parentCategory As List(Of DataClasses.Category)
        If catID Is Nothing Then
            'this is a base category
            parentCategory = (From x In db1.Categories Where x.Status = "Active" And x.ParentID Is Nothing Order By x.CategoryName Ascending).ToList
        Else
            'this is a subcategory of something
            parentCategory = (From x In db1.Categories Where x.Status = "Active" And x.CategoryID = CInt(catID) Order By x.CategoryName Ascending).ToList
        End If

        'subcategory
        Dim subcategory As List(Of DataClasses.Category)
        If catID Is Nothing Then
            'the parent category is a base category
            subcategory = (From x In db1.Categories Where x.Status = "Active" And x.ParentID IsNot Nothing Order By x.CategoryName Ascending).ToList
        Else
            'the parent category is a subcategory
            subcategory = (From x In db1.Categories Where x.Status = "Active" And x.ParentID = CInt(catID) Order By x.CategoryName Ascending).ToList
        End If

        'group the flat categories into a temp list
        'need to change this group join to account for multiple categories

        'On pcat.CategoryID Equals scat.ParentID
        'On pcat.CategoryID in(scat.ParentID)

        '18,4,28,7
        'categoryid | parentid 
        ' 1 | null
        ' 2 | null
        ' 3 | 1
        ' 4 | 1,3

        '                            On pcat.CategoryID Equals scat.ParentID

        Dim groupedCategories = (From pcat In parentCategory
                            Group Join scat In subcategory
                            On pcat.CategoryID Equals scat.ParentID
                            Into CategoryList = Group
                            Select pcat, CategoryList).tolist

        For Each cat In groupedCategories
            'this is a base category 
            If level = 0 Then
                'add this to the list with no manipulation
                myCategoryList.Add(cat.pcat)
            End If
            For Each subcat As DataClasses.Category In cat.CategoryList
                'this is a subcategory
                With subcat
                    'change the category name to show its depth
                    .CategoryName = repeatString(level + 1) & .CategoryName
                End With
                myCategoryList.Add(subcat)
                'run the function again with the new values for recursion
                createCategoryTree(subcat.CategoryID, level + 1)
            Next
        Next
    End Function
    Function repeatString(ByVal numtimes As Integer) As String
        'this function is going to build out the levels
        Dim myString = "-"
        repeatString = ""
        For x = 1 To numtimes
            repeatString = repeatString + myString
        Next
        Return repeatString
    End Function

#End Region

#Region " Public Subs "
    Public Sub checkLogin()
        If IsNothing(Session("loggedin")) Then
            Response.Redirect("login.aspx?returl=" & Request.Url.AbsoluteUri)
        End If
    End Sub
#End Region
#Region " Loading Routines "
    Public Sub LoadCategoryDDL()
        createCategoryTree()
        'lets add the top level option to the dropdown list
        Dim toplevellistitem As New ListItem("-- No Parent Category --", "toplevelcategory")
        ddlParentCategory.Items.Add(toplevellistitem)
        'now lets load up the rest of the categories
        If myCategoryList IsNot Nothing Then
            For Each category In myCategoryList.Where(Function(x) x.CategoryName.ToLower <> "uncategorized") 'filter out the uncategorized category
                Dim ilistitem As New ListItem(category.CategoryName, category.CategoryID)
                ddlParentCategory.Items.Add(ilistitem)
            Next
        End If
    End Sub
    Public Sub loadRecord()
        If oCategory IsNot Nothing Then
            'the category is valid, lets load up all the details
            With oCategory
                'general
                If .ParentID Is Nothing Then
                    ddlParentCategory.SelectedValue = "toplevelcategory"
                Else

                    ddlParentCategory.SelectedValue = .ParentID
                End If
                txtCategoryName.Text = .CategoryName
                txtMiniDescription.Text = .MiniDescription
                txtDescription.Text = .Description

                'seo
                txtSEOTitle.Text = .SEOTitle
                txtSEOSlug.Text = .SEOSlug
                txtSEOMetaDesc.Text = .SEODescription
                txtSEOMetaKeywords.Text = .SEOKeywords

                'otherdetails
                ddlFeatured.SelectedValue = .Featured
                txtSortOrder.Text = .SortOrder
                ddlStatus.SelectedValue = .Status

                'images
                txtImage1.Text = .ImagePath1
                txtImage2.Text = .ImagePath2
                txtImage3.Text = .ImagePath3
                txtImage4.Text = .ImagePath4

            End With
        End If
    End Sub
#End Region

#Region " Saving Routines "
    Public Sub SaveRecord()
        'find out if we are saving or inserting
        If oCategory IsNot Nothing Then
            'updating
            With oCategory
                'general
                .CategoryName = txtCategoryName.Text
                If ddlParentCategory.SelectedValue = "toplevelcategory" Then
                    .ParentID = Nothing
                Else
                    .ParentID = ddlParentCategory.SelectedValue
                End If
                If txtMiniDescription.Text = "" Then .MiniDescription = Nothing Else .MiniDescription = txtMiniDescription.Text
                If txtDescription.Text = "" Then .Description = Nothing Else .Description = txtDescription.Text

                'seo
                If txtSEOTitle.Text = "" Then .SEOTitle = Nothing Else .SEOTitle = txtSEOTitle.Text
                If txtSEOSlug.Text = "" Then .SEOSlug = Nothing Else .SEOSlug = txtSEOSlug.Text
                If txtSEOMetaDesc.Text = "" Then .SEODescription = Nothing Else .SEODescription = txtSEOMetaDesc.Text
                If txtSEOMetaKeywords.Text = "" Then .SEOKeywords = Nothing Else .SEOKeywords = txtSEOMetaKeywords.Text

                'other details
                .Featured = ddlFeatured.SelectedValue
                If txtSortOrder.Text = "" Then .SortOrder = "0" Else .SortOrder = txtSortOrder.Text
                .Status = ddlStatus.SelectedValue

                'images
                If txtImage1.Text = "" Then .ImagePath1 = Nothing Else .ImagePath1 = txtImage1.Text
                If txtImage2.Text = "" Then .ImagePath2 = Nothing Else .ImagePath2 = txtImage2.Text
                If txtImage3.Text = "" Then .ImagePath3 = Nothing Else .ImagePath3 = txtImage3.Text
                If txtImage4.Text = "" Then .ImagePath4 = Nothing Else .ImagePath4 = txtImage4.Text

                .DateModified = Now
            End With
        Else
            'inserting
            Dim myNewCategory As New DataClasses.Category
            With myNewCategory
                'general
                .CategoryName = txtCategoryName.Text
                If ddlParentCategory.SelectedValue = "toplevelcategory" Then
                    .ParentID = Nothing
                Else
                    .ParentID = ddlParentCategory.SelectedValue
                End If
                If txtMiniDescription.Text = "" Then .MiniDescription = Nothing Else .MiniDescription = txtMiniDescription.Text
                If txtDescription.Text = "" Then .Description = Nothing Else .Description = txtDescription.Text

                'seo
                If txtSEOTitle.Text = "" Then .SEOTitle = Nothing Else .SEOTitle = txtSEOTitle.Text
                If txtSEOSlug.Text = "" Then .SEOSlug = Nothing Else .SEOSlug = txtSEOSlug.Text
                If txtSEOMetaDesc.Text = "" Then .SEODescription = Nothing Else .SEODescription = txtSEOMetaDesc.Text
                If txtSEOMetaKeywords.Text = "" Then .SEOKeywords = Nothing Else .SEOKeywords = txtSEOMetaKeywords.Text

                'other details
                .Featured = ddlFeatured.SelectedValue
                If txtSortOrder.Text = "" Then .SortOrder = "0" Else .SortOrder = txtSortOrder.Text
                .Status = ddlStatus.SelectedValue

                'images
                If txtImage1.Text = "" Then .ImagePath1 = Nothing Else .ImagePath1 = txtImage1.Text
                If txtImage2.Text = "" Then .ImagePath2 = Nothing Else .ImagePath2 = txtImage2.Text
                If txtImage3.Text = "" Then .ImagePath3 = Nothing Else .ImagePath3 = txtImage3.Text
                If txtImage4.Text = "" Then .ImagePath4 = Nothing Else .ImagePath4 = txtImage4.Text

                .DateCreated = Now
                .DateModified = Now

            End With
            db.Categories.InsertOnSubmit(myNewCategory)
        End If
        db.SubmitChanges()
    End Sub
#End Region

#Region " Deleting Routines "
    Private Sub btnRemoveImg1_Click(sender As Object, e As EventArgs) Handles btnRemoveImg1.Click
        Dim myImage = txtImage1.Text
        'select from database
        Dim myRecord = (From x In db.Categories Where x.CategoryID = CInt(CategoryID)).SingleOrDefault
        'delete from database
        If myRecord IsNot Nothing Then
            With myRecord
                .ImagePath1 = Nothing
            End With
            db.SubmitChanges()
        End If
        'delete from filesystem
        Dim myFile = Server.MapPath(myImage)
        Try
            System.IO.File.Delete(myFile)
        Catch ex As Exception
        End Try

        txtImage1.Text = ""
        Response.Write("<script>$('#Image1').hide();</script>")

    End Sub
    Private Sub btnRemoveImg2_Click(sender As Object, e As EventArgs) Handles btnRemoveImg2.Click
        Dim myImage = txtImage2.Text
        'select from database
        Dim myRecord = (From x In db.Categories Where x.CategoryID = CInt(CategoryID)).SingleOrDefault
        'delete from database
        If myRecord IsNot Nothing Then
            With myRecord
                .ImagePath2 = Nothing
            End With
            db.SubmitChanges()
        End If
        'delete from filesystem
        Dim myFile = Server.MapPath(myImage)
        Try
            System.IO.File.Delete(myFile)
        Catch ex As Exception
        End Try

        txtImage2.Text = ""
        Response.Write("<script>$('#Image2').hide();</script>")

    End Sub

    Private Sub btnRemoveImg3_Click(sender As Object, e As EventArgs) Handles btnRemoveImg3.Click
        Dim myImage = txtImage3.Text
        'select from database
        Dim myRecord = (From x In db.Categories Where x.CategoryID = CInt(CategoryID)).SingleOrDefault
        'delete from database
        If myRecord IsNot Nothing Then
            With myRecord
                .ImagePath3 = Nothing
            End With
            db.SubmitChanges()
        End If
        'delete from filesystem
        Dim myFile = Server.MapPath(myImage)
        Try
            System.IO.File.Delete(myFile)
        Catch ex As Exception
        End Try

        txtImage3.Text = ""
        Response.Write("<script>$('#Image3').hide();</script>")

    End Sub

    Private Sub btnRemoveImg4_Click(sender As Object, e As EventArgs) Handles btnRemoveImg4.Click
        Dim myImage = txtImage4.Text
        'select from database
        Dim myRecord = (From x In db.Categories Where x.CategoryID = CInt(CategoryID)).SingleOrDefault
        'delete from database
        If myRecord IsNot Nothing Then
            With myRecord
                .ImagePath4 = Nothing
            End With
            db.SubmitChanges()
        End If
        'delete from filesystem
        Dim myFile = Server.MapPath(myImage)
        Try
            System.IO.File.Delete(myFile)
        Catch ex As Exception
        End Try

        txtImage4.Text = ""
        Response.Write("<script>$('#Image4').hide();</script>")

    End Sub
#End Region


    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        checkLogin()
        If Not IsPostBack Then
            'lets do the first load of the categories
            LoadCategoryDDL()
            loadRecord()
        End If

    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        SaveRecord()
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Response.Redirect("action.aspx?action=deletecategory&id=" & CategoryID & "&returl=/admin/categories.aspx")
    End Sub


End Class