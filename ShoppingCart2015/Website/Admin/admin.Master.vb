Public Class admin1
    Inherits System.Web.UI.MasterPage
    Private db As DataContext = DataContext.Current(True)

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
    Public ReadOnly Property iCategoryCount As Integer
        Get
            Dim productCount = (From x In db.Categories Where x.Status <> "Deleted").Count
            If productCount > 0 Then
                Return productCount
            Else
                Return 0
            End If
        End Get
    End Property
#End Region

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

End Class