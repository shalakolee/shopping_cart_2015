<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Admin/admin.Master" CodeBehind="default.aspx.vb" Inherits="Website.WebForm2" %>
<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="bodyContent" runat="server">
    <script>
        $(function () {
            Morris.Area({
                element: 'morris-area-chart',
                data: [
                    <%
        If oOrders IsNot Nothing Then
            For Each order In oOrders
        %>
                {
                    OrderDate: '<%=order.CreateDate.ToString("yyyy-MM-dd")%>',
                    orderTotal: '<%=order.GrandTotal%>'
                },

        <%
            Next

        End If
                    %>

                ],
                xkey: 'OrderDate',
                ykeys: ['orderTotal'],
                labels: ['orderTotal'],
                pointSize: 1,
                hideHover: 'auto',
                resize: true
            });


            Morris.Donut({
                element: 'morris-donut-chart',
                data: [{
                    label: "Complete Orders",
                    value: <%=iCompleteOrders%>,
                    href:"orders.aspx"
                }, {
                    label: "Orders Pending Payment",
                    value: <%=iPendingPaymentCount%>,
                    href:"orders.aspx"
                }, {
                    label: "Orders Pending Shipment",
                    value: <%=iPendingShipmentCount%>,
                    href:"orders.aspx"
                },{
                    label: "Voided Orders",
                    value: <%=iVoidedOrders%>,
                    href:"orders.aspx"
                }],
                resize: true
            }).on('click', function(i, chartitem){
                +  console.log(i, chartitem.href);
            });

        });
    </script>
                    <div class="row">
                    <div class="col-lg-12">
                        <h1 class="page-header">Dashboard</h1>
                    </div>
                    <!-- /.col-lg-12 -->
                </div>

    <div class="panel-body" style="width:49%;float:left;">
        <div id="morris-donut-chart"></div>
    </div>
    <div class="panel-body" style="width:49%;float:right;">
        <div id="morris-area-chart"></div>
    </div>
    <div style="clear:both;"></div>

</asp:Content>

