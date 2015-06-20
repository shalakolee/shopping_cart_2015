<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Admin/admin.Master" CodeBehind="login.aspx.vb" Inherits="Website.WebForm1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="bodyContent" runat="server">
    
           
    <!--  LOGIN FORM -->

    <div style="width:300px;box-shadow:0 0 30px black;margin:auto;margin-top:75px;" class="rounded10"  >
        <img src="/images/561_Master_Logo.jpg" style="max-width:300px;"  />
    </div>

    <div style="width: 300px; margin: auto;box-shadow: 0 0 30px black;margin-top:60px;" class="panel panel-default">
        <div class="panel-heading">
            Login
        </div>
        <div class="panel-body" style="text-align:left;" >
            <asp:Panel runat="server" ID="phFeedBack" Visible="false" CssClass="alert alert-danger alert-dismissable">
                  <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                  <asp:label id="lblFeedback" runat="server" />
            </asp:Panel>
            <div class="formRow">
                <label>Username</label>
                <asp:TextBox runat="server" ID="txtUserName" CssClass="form-control" />
            </div>
            <div class="formRow">
                <label>Password</label>
                <asp:TextBox runat="server" ID="txtPassword" CssClass="form-control" TextMode="Password" />
            </div>
            <div style="margin-top:20px;">
                <asp:Button runat="server" ID="btnLogin" CssClass="btn btn-default right" Text="Login" />
            </div>
        </div>
    </div>
    <!-- /LOGIN FORM -->

</asp:Content>
