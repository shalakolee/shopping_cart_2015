Public Class WebForm2
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current()

#Region " Page Summary "
    ''' <summary>
    ''' show general information on this page
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
#End Region

#Region " Linq Properties "
    Public ReadOnly Property iPendingShipmentCount As Integer
        Get
            Dim myCount = (From x In db.Orders Where x.Status = "Pending Shipment").Count
            If myCount > 0 Then
                Return myCount
            Else
                Return 0
            End If
        End Get
    End Property
    Public ReadOnly Property iCompleteOrders As Integer
        Get
            Dim myCount = (From x In db.Orders Where x.Status = "Completed").Count
            If myCount > 0 Then
                Return myCount
            Else
                Return 0
            End If
        End Get
    End Property
    Public ReadOnly Property iVoidedOrders As Integer
        Get
            Dim myCount = (From x In db.Orders Where x.Status = "Voided").Count
            If myCount > 0 Then
                Return myCount
            Else
                Return 0
            End If
        End Get
    End Property
    Public ReadOnly Property iPendingPaymentCount As Integer
        Get
            Dim myCount = (From x In db.Orders Where x.Status = "Pending Payment").Count
            If myCount > 0 Then
                Return myCount
            Else
                Return 0
            End If
        End Get
    End Property
    Public ReadOnly Property iProductCount As Integer
        Get
            Dim productCount = (From x In db.Products Where x.Status <> "Deleted").Count
            If productCount > 0 Then
                Return productCount
            Else
                Return 0
            End If
        End Get
    End Property
    Public ReadOnly Property oOrders As List(Of DataClasses.Order)
        Get
            Dim myorders = (From x In db.Orders).ToList
            If myorders IsNot Nothing Then
                Return myorders
            Else
                Return Nothing
            End If
        End Get
    End Property
#End Region

#Region " Button Events "

#End Region

#Region " Loading "
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        'checkLogin()
    End Sub

#End Region

#Region " Public Subs "
    Public Sub checkLogin()
        If IsNothing(Session("loggedin")) Then
            Response.Redirect("login.aspx?returl=" & Request.Url.AbsoluteUri)
        End If
    End Sub
#End Region
End Class