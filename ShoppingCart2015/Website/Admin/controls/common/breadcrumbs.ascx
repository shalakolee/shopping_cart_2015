<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="breadcrumbs.ascx.vb" Inherits="Website.breadcrumbs" %>

<div class="BreadCrumbs left">
    <%= sBreadCrumbs%>
</div>

<div class="BreadCrumbsUsername right">
    Logged in as: <%= Session("Username")%>
</div>

<div style="clear: both;"></div>
