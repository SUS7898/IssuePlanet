<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>IssuePlanet - 내 정보</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8fafc; font-family: 'Pretendard', -apple-system, sans-serif; }
        .info-container { max-width: 600px; margin: 60px auto; padding: 40px; background: #ffffff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); }
        .title { font-size: 26px; font-weight: 800; color: #1e3a8a; margin-bottom: 35px; text-align: center; letter-spacing: -0.5px; }
        .info-group { display: flex; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #f1f5f9; padding-bottom: 14px; }
        .info-label { font-weight: 600; color: #475569; width: 140px; display: inline-block; }
        .info-value { color: #1e293b; font-size: 16px; }
        .btn-group-custom { display: flex; gap: 12px; margin-top: 35px; }
        .btn-custom { flex: 1; padding: 14px; font-weight: 600; border-radius: 8px; text-decoration: none; text-align: center; transition: all 0.2s; }
        .btn-custom:hover { transform: translateY(-1px); }
    </style>
</head>
<body>

    <div class="info-container">
        <div class="title">내 정보 상세 보기</div>
        
        <div class="info-group">
            <span class="info-label">아이디</span>
            <span class="info-value"><c:out value="${member.id}" /></span>
        </div>
        <div class="info-group">
            <span class="info-label">이름</span>
            <span class="info-value"><c:out value="${member.userName}" /></span>
        </div>
        <div class="info-group">
            <span class="info-label">전화번호</span>
            <span class="info-value">${not empty member.mobile ? member.mobile : '등록되지 않음'}</span>
        </div>
        <div class="info-group">
            <span class="info-label">우편번호</span>
            <span class="info-value">${not empty postcode ? postcode : '등록되지 않음'}</span>
        </div>
        <div class="info-group">
            <span class="info-label">기본 주소</span>
            <span class="info-value">${not empty member.address ? member.address : '등록되지 않음'}</span>
        </div>
        <div class="info-group">
            <span class="info-label">상세 주소</span>
            <span class="info-value">${not empty detailAddress ? detailAddress : '등록되지 않음'}</span>
        </div>

        <div class="btn-group-custom">
            <a href="/member/update" class="btn btn-primary btn-custom">정보 수정</a>
            <a href="/member/delete" class="btn btn-danger btn-custom">회원 탈퇴</a>
            <a href="/index" class="btn btn-secondary btn-custom">메인화면</a>
        </div>
    </div>

</body>
</html>