Public Class breadcrumbs
    Inherits System.Web.UI.UserControl

#Region " Declarations "

    Protected sBreadCrumbs As String
    Public AdminPath As String = ConfigurationManager.AppSettings("AdminPath")

#End Region

#Region " Helper Methods "

    Private Function MakeLink(ByVal Name As String, ByVal URL As String, Optional ByVal Enabled As Boolean = True) As String
        Dim oLink As New StringBuilder
        With oLink
            If Enabled Then
                .Append("<A href=""")
                .Append(AdminPath)
                .Append(URL)
                .Append(""">")
                .Append(Name)
                .Append("</A>")
            Else
                .Append("<SPAN class=""DisabledLink"">")
                .Append(Name)
                .Append("</SPAN>")
            End If

            Return .ToString
        End With
    End Function

    Protected Function DisplayCrumbs() As String

        Select Case Request.Url.AbsolutePath.ToUpper.Substring(Request.Url.AbsolutePath.LastIndexOf("/"))
            Case "/ACTION.ASPX"
                Select Case Trim(Request.QueryString("mode")).ToUpper
                    Case "DELETECATEGORY"
                        Return MakeLink("Home Screen", "/") & " &raquo; " & _
                               MakeLink("Product Categories", "/categories.aspx") & " &raquo; " & _
                               MakeLink("Delete Category", "#", False)
                    Case "DELETECOUPON"
                        Return MakeLink("Home Screen", "/") & " &raquo; " & _
                               MakeLink("Coupon Management", "/coupons.aspx") & " &raquo; " & _
                               MakeLink("Delete Coupon", "#", False)
                    Case "DELETEPRODUCT"
                        Return MakeLink("Home Screen", "/") & " &raquo; " & _
                               MakeLink("Product Management", "/products.aspx") & " &raquo; " & _
                               MakeLink("Delete Product", "#", False)
                    Case "VOIDORDER"
                        Return MakeLink("Home Screen", "/") & " &raquo; " & _
                               MakeLink("Order Management", "/orders.aspx") & " &raquo; " & _
                               MakeLink("Void Order", "#", False)
                    Case "DELETESITE"
                        Return MakeLink("Home Screen", "/") & " &raquo; " & _
                               MakeLink("Site Management", "/sites.aspx") & " &raquo; " & _
                               MakeLink("Delete Site", "#", False)
                    Case Else
                        Return MakeLink("Home Screen", "/")
                End Select

            Case "/ORDERS.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Order Management", "/orders.aspx")

            Case "/ORDER.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Order Management", "/orders.aspx") & " &raquo; " & _
                       MakeLink("Order Details", "#", False)

            Case "/PRODUCTS.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Management", "/products.aspx")

            Case "/PRODUCT.ASPX"
                Dim sTitle As String
                If Request.QueryString("productid") <> "" Then
                    sTitle = "Edit Product"
                Else
                    sTitle = "Add New Product"
                End If
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Management", "/products.aspx") & " &raquo; " & _
                       MakeLink(sTitle, "#", False)

            Case "/PRODUCTIMAGES.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Management", "/products.aspx") & " &raquo; " & _
                       MakeLink("Edit Product Images", "#", False)

            Case "/PRODUCTOPTION.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Management", "/products.aspx") & " &raquo; " & _
                       MakeLink("Edit Product", Request.QueryString("redir")) & " &raquo; " & _
                       MakeLink("Edit Product Option Values", "#", False)

            Case "/CATEGORIES.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Categories", "/categories.aspx")

            Case "/CATEGORY.ASPX"
                Dim sTitle As String
                If Request.QueryString("categoryid") <> "" Then
                    sTitle = "Edit Category"
                Else
                    sTitle = "Add Category"
                End If
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Product Categories", "/categories.aspx") & " &raquo; " & _
                       MakeLink(sTitle, "#", False)

            Case "/COUPONS.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Coupon Management", "/coupons.aspx")

            Case "/COUPON.ASPX"
                Dim sTitle As String
                If Request.QueryString("couponid") <> "" Then
                    sTitle = "Edit Coupon"
                Else
                    sTitle = "Add Coupon"
                End If
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Coupon Management", "/coupons.aspx") & " &raquo; " & _
                       MakeLink(sTitle, "#", False)

            Case "/STATES.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("State Sales Tax", "/states.aspx")

            Case "/SITES.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Site Management", "/sites.aspx")

            Case "/SITE.ASPX"
                Dim sTitle As String
                If Request.QueryString("siteid") <> "" Then
                    sTitle = "Edit Site"
                Else
                    sTitle = "Add New Site"
                End If
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Site Management", "/sites.aspx") & " &raquo; " & _
                       MakeLink(sTitle, "#", False)

            Case "/SHIPPING.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Shipping Options", "/shipping.aspx")

            Case "/WHOLESALEUSERS.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                        MakeLink("Wholesaler Account Management", "/wholesaleusers.aspx")
            Case "/WHOLESALEUSER.ASPX"
                Dim sTitle As String
                If Request.QueryString("UserId") <> "" Then
                    sTitle = "Edit Account"
                Else
                    sTitle = "Add New Account"
                End If

                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Wholesaler Account Management", "/wholesaleusers.aspx") & " &raquo; " & _
                       MakeLink(sTitle, "#", False)
            Case "/CONTENTEDITOR.ASPX"
                Return MakeLink("Home Screen", "/") & " &raquo; " & _
                       MakeLink("Content Editor", "/contenteditor.aspx", False)
            Case Else
                Return MakeLink("Home Screen", "/")
        End Select

    End Function

#End Region

#Region " Loading Methods "

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Nothing defined yet
    End Sub

#End Region

#Region " Event Handlers "

    Private Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        sBreadCrumbs = DisplayCrumbs()
    End Sub

#End Region

End Class