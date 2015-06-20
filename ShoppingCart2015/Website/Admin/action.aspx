<%@ Page Title="" Language="vb" AutoEventWireup="false"  CodeBehind="action.aspx.vb" Inherits="Website.adminActions" %>

<script src="../scripts/jquery-2.1.1.js"></script>
<script src="../scripts/jquery-ui-1.10.4.js"></script>
<script src="../scripts/bootstrap.js"></script>
<link href="../css/bootstrap.css" rel="stylesheet" />
<form runat="server">
              <div style="width: 500px; margin: auto; text-align: center;box-shadow: 0 0 30px black;margin-top:200px;" class="rounded8">
                <div class="alert alert-warning">
                    <asp:PlaceHolder ID="phActions" runat="server">
                        Are you sure you want to <strong>
                            <asp:Label runat="server" ID="lblAction" /></strong> the
                        <asp:Label runat="server" ID="lblItemType" />
                        <strong>
                            <asp:Label runat="server" ID="lblItemName" /></strong>?<br />
                        <br />
                    </asp:PlaceHolder>
                    <asp:PlaceHolder ID="phActionNotValid" runat="server" Visible="false" >
                        <div><asp:Label ID="lblError" runat="server" /></div>
                    </asp:PlaceHolder>
                    <div class="btn btn-warning" id="cancelBtn" >Cancel</div>
                    <script>
                        $("#cancelBtn").click(function () { window.location.href='<%=Request("returl")%>'; return false; });
                    </script>
                    <asp:Button runat="server" ID="btnConfirm" Text="Confirm Action" CssClass="btn btn-danger" />
                </div>
            </div>

</form>