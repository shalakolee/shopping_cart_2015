Public Class AdminCategories
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current(True)
    Private myCategoryList As New List(Of DataClasses.Category)

#Region " Category Listings "
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

        'only going to filter out deleted items here


        'parent category
        Dim parentCategory As List(Of DataClasses.Category)
        If catID Is Nothing Then
            'this is a base category
            parentCategory = (From x In db.Categories Where x.Status <> "Deleted" And x.ParentID Is Nothing Order By x.CategoryName Ascending).ToList
        Else
            'this is a subcategory of something
            parentCategory = (From x In db.Categories Where x.Status <> "Deleted" And x.CategoryID = CInt(catID) Order By x.CategoryName Ascending).ToList
        End If

        'subcategory
        Dim subcategory As List(Of DataClasses.Category)
        If catID Is Nothing Then
            'the parent category is a base category
            subcategory = (From x In db.Categories Where x.Status <> "Deleted" And x.ParentID IsNot Nothing Order By x.CategoryName Ascending).ToList
        Else
            'the parent category is a subcategory
            subcategory = (From x In db.Categories Where x.Status <> "Deleted" And x.ParentID = CInt(catID) Order By x.CategoryName Ascending).ToList
        End If

        'group the flat categories into a temp list
        'need to change this group join to account for multiple categories

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

#Region " Paging "

    ''' <summary>
    ''' This is for paging
    ''' </summary>
    ''' <param name="sender"></param>
    ''' <param name="e"></param>
    ''' <remarks>
    ''' thanks brendon for the awesome code
    ''' Usage:
    ''' </remarks>


    Protected Sub lnkNext_Click(sender As Object, e As EventArgs) Handles lnkNext.Click
        hdnCurrentPage.Value = CInt(hdnCurrentPage.Value) + 1
        loadFromDatabase(CInt(ddlPager.SelectedValue))
    End Sub

    Protected Sub lnkPrev_Click(sender As Object, e As EventArgs) Handles lnkPrev.Click
        hdnCurrentPage.Value = CInt(hdnCurrentPage.Value) - 1
        loadFromDatabase(CInt(ddlPager.SelectedValue))
    End Sub
    Public Property iPageNumber As Integer
        Get
            Return CInt(hdnCurrentPage.Value)
        End Get
        Set(value As Integer)
        End Set

    End Property
    Protected Sub ddlPager_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlPager.SelectedIndexChanged
        Try
            loadFromDatabase(CInt(ddlPager.SelectedValue))
        Catch ex As Exception

        End Try
    End Sub
    Protected Function getMaxPages(intRowCount As Integer, ByRef intPageSkip As Integer, iResultsPerPage As Integer) As Integer
        getMaxPages = 1
        Try
            ' We need to determine a couple of things for the search
            ' First the maximum page numbers for the search

            Dim i As Integer = 0
            Dim blnExtraPage As Boolean = False

            i = Math.Floor(intRowCount / iResultsPerPage)

            If intRowCount Mod iResultsPerPage > 0 Then
                ' add an extra page
                i = i + 1
            End If

            getMaxPages = i

            If iPageNumber > i Then
                iPageNumber = i
            End If

            If iPageNumber < 1 Then
                iPageNumber = 1
            End If

            ' Lets turn the appropriate controls visibilty on or off
            If iPageNumber > 0 Then
                lnkNext.Enabled = True
                lnkPrev.Enabled = True
            End If

            ' Lets test for first page
            If iPageNumber = 1 Then
                lnkPrev.Enabled = False
            End If

            ' Lets test for the final page
            If iPageNumber >= i Then
                lnkNext.Enabled = False

            End If

            If lnkNext.Enabled Then
                lnkNext.ForeColor = Drawing.Color.FromArgb(0, 52, 146, 157)
            Else
                lnkNext.ForeColor = Drawing.Color.LightGray
            End If
            If lnkPrev.Enabled Then
                lnkPrev.ForeColor = Drawing.Color.FromArgb(0, 52, 146, 157)
            Else
                lnkPrev.ForeColor = Drawing.Color.LightGray
            End If

            If getMaxPages < CInt(hdnCurrentPage.Value) Then
                hdnCurrentPage.Value = getMaxPages
            End If

            intPageSkip = CInt(hdnCurrentPage.Value) - 1

            intPageSkip = intPageSkip * iResultsPerPage

            If intRowCount = 0 Then
                getMaxPages = 1
                hdnCurrentPage.Value = "1"
                intPageSkip = 0
            End If

        Catch ex As Exception
        End Try
    End Function
#End Region

#Region " Public Subs "
    Public Sub checkLogin()
        If IsNothing(Session("loggedin")) Then
            Response.Redirect("login.aspx?returl=" & Request.Url.AbsoluteUri)
        End If
    End Sub
#End Region
#Region " Public Functions "
    Public Function GetImage(ByVal CategoryID As Integer, imagepath1 As String)
        'if the category has a main image we will return the html for the image, otherwise we will return nothing
        Dim myCategory = (From c In db.Categories Where c.CategoryID = CategoryID).SingleOrDefault
        If myCategory.ImagePath1 <> "" Then
            Dim response As String = "<a href='" & imagepath1 & "' class='fancybox'><img src='/code/ImageProcessor.ashx?image=" & imagepath1 & "&w=75&h=75&preserve=true' style='max-width: 75px;' /></a> "
            Return response ' "<img src='<%#/code/ImageProcessor.ashx?image=' & ConfigurationManager.AppSettings('CategoryImagesFolder') & Eval('ImagePath1') & '&w=75&h=75&preserve=true'%>' style='max-width: 75px;display:<%#getimagedisplay(eval('categoryid'))%>;' />"
        Else
            Return ""
        End If
    End Function
    Public Function loadFromDatabase(Optional ByVal intPager As Integer = -1, Optional ByVal pgNumber As Integer = 1) As Boolean
        loadFromDatabase = False
        Try
            'lets create the category tree
            createCategoryTree()

            'now lets use the tree list instead of pulling from the database
            Dim myCategories = (From x In myCategoryList Where x.CategoryName.ToLower <> "uncategorized").ToList

            'lets filter by category status 
            If cboStatus.SelectedValue = "Active" Then
                myCategories = (From x In myCategories Where x.Status = "Active").ToList
            ElseIf cboStatus.SelectedValue = "Inactive" Then
                myCategories = (From x In myCategories Where x.Status = "Inactive").ToList
            End If

            Dim iPageSkip As Integer = 0
            Dim intMaxPage As Integer = 1

            If CInt(ddlPager.SelectedValue) = 0 Then
                intMaxPage = getMaxPages(myCategories.Count, iPageSkip, myCategories.Count)
            Else
                intMaxPage = getMaxPages(myCategories.Count, iPageSkip, CInt(ddlPager.SelectedValue))
            End If

            ' Take per page value 
            If intPager > -1 Then
                If intPager > 0 Then
                    myCategories = myCategories.Skip((iPageSkip)).Take(intPager).ToList
                End If
            Else
                myCategories = myCategories.Skip((iPageSkip)).ToList 'taking all by default
                'myCategories = myCategories.Skip((iPageSkip)).Take(12).ToList ' setting 12 as default for now - default load
            End If

            rptOffices.DataSource = myCategories.ToList
            rptOffices.DataBind()

            lblPage.Text = hdnCurrentPage.Value & " of " & intMaxPage.ToString()
            db.Dispose()
        Catch ex As Exception
        End Try
    End Function

#End Region

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        checkLogin()

        If Not IsPostBack Then
            'lets do the first load of the categories
            loadFromDatabase()
        End If
    End Sub
    Private Sub cboStatus_SelectedIndexChanged(sender As Object, e As EventArgs) Handles cboStatus.SelectedIndexChanged
        loadFromDatabase(CInt(ddlPager.SelectedValue))
    End Sub

End Class