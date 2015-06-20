Public Class test
    Inherits System.Web.UI.Page
    Private db As DataContext = DataContext.Current(True)

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If db Is Nothing Then
            Response.Write("Could Not Connect to Database, Please check the connection Settings")
            Exit Sub
        End If

        Dim test = (From x In db.Products Where x.ProductID = 1).SingleOrDefault
        With test
            .ProductCode = "LesPaul1"
        End With
        db.SubmitChanges()
    End Sub

End Class