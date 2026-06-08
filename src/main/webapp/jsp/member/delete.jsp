<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="/header" />

<div align="center">
<h1>회원 탈퇴</h1>
<table>
	<tr><td>${msg }</td></tr>
	<tr><td>
	<form action="deleteProc" method="post">
		<input type="text" value="${sessionScope.id }" readonly="readonly"> <br>
		<input type="password" placeholder="비밀번호" name="pw"><br>
		<input type="password" placeholder="비밀번호 확인" name="confirm"><br>
		<input type="submit" value="회원 탈퇴"> 
		<input type="button" value="취소" onclick="location.href='index'">
	</form>
	</td></tr>
</table>
</div>

<c:import url="/footer" />








