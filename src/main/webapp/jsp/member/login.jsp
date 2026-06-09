<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>IssuePlanet - 로그인</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8fafc; font-family: 'Pretendard', -apple-system, sans-serif; }
        .login-container { max-width: 450px; margin: 80px auto; padding: 40px; background: #ffffff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); }
        .brand-logo { font-size: 28px; font-weight: 800; color: #1e3a8a; text-align: center; margin-bottom: 30px; letter-spacing: -0.5px; }
        .form-control { padding: 12px 16px; border-radius: 8px; border: 1px solid #cbd5e1; margin-top: 6px; }
        .form-control:focus { border-color: #1e3a8a; box-shadow: 0 0 0 3px rgba(30, 58, 138, 0.1); }
        .btn-primary { background-color: #1e3a8a; border: none; font-weight: 600; border-radius: 8px; transition: all 0.2s; }
        .btn-primary:hover { background-color: #1d4ed8; transform: translateY(-1px); }
    </style>
</head>
<body>
	<c:import url="/header"/>
    <c:if test="${not empty msg}">
        <script>alert("${msg}");</script>
    </c:if>

    <div class="login-container">
        <div class="brand-logo">IssuePlanet</div>
        
        <form id="f" action="/member/loginProc" method="post">
            <div style="margin-bottom: 20px;">
                <label style="font-weight: 600; color: #475569;">아이디</label>
                <input type="text" id="id" name="id" class="form-control" placeholder="아이디를 입력하세요">
            </div>
            <div style="margin-bottom: 30px;">
                <label style="font-weight: 600; color: #475569;">비밀번호</label>
                <input type="password" id="pw" name="pw" class="form-control" placeholder="비밀번호를 입력하세요">
            </div>
            
            <button type="button" class="btn btn-primary" style="width: 100%; padding: 14px; font-size: 16px;" onclick="loginCheck()">로그인</button>
        </form>
        
        <div style="text-align: center; margin-top: 24px; font-size: 14px; color: #64748b;">
            아직 회원이 아니신가요? <a href="/member/regist" style="color: #1e3a8a; font-weight: 600; text-decoration: none; margin-left: 6px;">회원가입</a>
        </div>
    </div>

    <script src="/dbQuiz.js"></script>
    	<c:import url="/footer"/>
</body>
</html>