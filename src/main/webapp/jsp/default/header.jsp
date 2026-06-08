<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<style type="text/css">
	a {text-decoration: none; color:black;}
	ul {padding: 20px;}
	ul li {display: inline; padding: 15px;}
	.main_div{height: 150px; padding-top : 80px;}
</style>    

<script src="dbQuiz.js"></script>

<div align="center">
	<h1>CARE</h1>
</div>

<c:url var="context" value="/"/>
<div align="right">
	<hr>
	<ul>
		<li><a href="${context }index">HOME</a></li>
		<li><a href="${context }regist">Regist</a></li>
		<c:choose>
			<c:when test="${empty sessionScope.id }">
				<li><a href="${context }login">Login</a></li>
			</c:when>
			<c:otherwise>
				<li><a href="${context }logout">Logout</a></li>
			</c:otherwise>
		</c:choose>
		<li><a href="${context }memberInfo">MemberInfo</a></li>
		<li><a href="${context }boardForm">Board</a></li>
	</ul>
	<hr>
</div>








