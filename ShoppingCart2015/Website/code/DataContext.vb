Partial Class DataContext
    Shared Function Current() As DataContext
        Return Current(False)
    End Function
    'defining this class so that we can use these variables
    Public Class ConnectionString
        Public Property DatabaseServer As String
        Public Property Database As String
        Public Property DatabaseEnvironment As String
        Public Property DatabaseUsername As String
        Public Property DatabasePassword As String
        Public Property DatabaseConnectionTimeout As Integer

    End Class
    Shared Function Current(ByVal Updatable As Boolean) As DataContext
        'create a new connection list
        Dim myConnectionList As New List(Of ConnectionString)

        'grab up the databases list from the web.config
        Dim ConnectionsArray = Split(ConfigurationManager.AppSettings("Databases"), ";")

        'loop through each one and add it to the connection string list
        For Each Conn In ConnectionsArray
            Dim myConnectionString As New ConnectionString
            'split the connection into array
            Dim connValues = Split(Conn, ",")
            With myConnectionString
                .DatabaseServer = connValues(0)
                .Database = connValues(1)
                .DatabaseEnvironment = connValues(2)
                .DatabaseUsername = ConfigurationManager.AppSettings("UserName")
                .DatabasePassword = ConfigurationManager.AppSettings("Password")
                .DatabaseConnectionTimeout = ConfigurationManager.AppSettings("ConnectTimeout")
            End With
            myConnectionList.Add(myConnectionString)
        Next
        'use the connnection string that is selected in the web.config
        Dim myConnection = (From x In myConnectionList Where x.DatabaseEnvironment = ConfigurationManager.AppSettings("Database")).SingleOrDefault

        If myConnection IsNot Nothing Then
            'try to connect to the database
            Dim oDC As New DataContext("SERVER=" & myConnection.DatabaseServer & ";DATABASE=" & myConnection.Database & _
                                        ";UID=" & myConnection.DatabaseUsername & ";PWD=" & myConnection.DatabasePassword & _
                                        ";TIMEOUT=" & myConnection.DatabaseConnectionTimeout)

            oDC.ObjectTrackingEnabled = Updatable

            'if we can connect to the database then lets return the connection
            Return oDC
        Else
            Return Nothing
        End If

    End Function

    Shared Function Current(ByVal Conn As SqlConnection, ByVal Updatable As Boolean) As DataContext

        Dim oDC As New DataContext(Conn)
        oDC.ObjectTrackingEnabled = Updatable
        Return oDC

    End Function

    Shared Function Current(ByVal Conn As SqlConnection, ByVal Trans As SqlTransaction, ByVal Updatable As Boolean) As DataContext

        Dim oDC As New DataContext(Conn)
        oDC.ObjectTrackingEnabled = Updatable
        oDC.Transaction = Trans
        Return oDC

    End Function

End Class

