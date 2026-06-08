<%@ page language="java" contentType="text/html; charset=UTF-8"   pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="/header" />

<div align="center">
	<h1>개인 정보</h1>
	아이디 : ${member.id } <br> 
	비밀번호 : ${member.pw }<br>
	이름 : ${member.userName }<br>
	우편번호 : ${postcode } <br>
	주소 : ${member.address } <br>
	상세주소 : ${detailAddress } <br>
	전화번호 : ${member.mobile } <br><br>
	<button type="button" onclick="location.href='update'">회원 수정</button>
	<button type="button" onclick="location.href='delete'">회원 삭제</button>
</div>	

<c:import url="/footer"/>



















