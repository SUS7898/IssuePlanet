<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>IssuePlanet</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap" rel="stylesheet">
<style>
    /* 공통 스타일 */
    body { font-family: 'Noto Sans KR', sans-serif; margin: 0; background-color: #f4f6f9; color: #333; }
    .container { max-width: 900px; margin: 40px auto; background: #fff; padding: 40px; border-radius: 12px; box-shadow: 0 8px 16px rgba(0,0,0,0.05); }
    
    /* 네비게이션 바 */
    .navbar { background: #1a1b26; padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; }
    .navbar-brand { font-size: 26px; font-weight: 700; color: #fff; text-decoration: none; letter-spacing: 1px; }
    .nav-links a { color: #a9b1d6; text-decoration: none; margin: 0 15px; font-weight: 500; transition: 0.3s; }
    .nav-links a:hover { color: #fff; }
    
    /* 버튼 스타일 */
    .btn { padding: 10px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 14px; transition: 0.2s; text-decoration: none; display: inline-block; }
    .btn-primary { background: #7aa2f7; color: white; }
    .btn-primary:hover { background: #5d89e5; }
    .btn-secondary { background: #e2e8f0; color: #475569; }
    .btn-secondary:hover { background: #cbd5e1; }
    .btn-danger { background: #f7768e; color: white; }
    
    /* 게시판 테이블 */
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 15px; border-bottom: 1px solid #f1f5f9; text-align: center; font-size: 15px; }
    th { background: #f8fafc; color: #64748b; font-weight: 600; }
    tr:hover { background: #f8fafc; }
    .title-cell { text-align: left; padding-left: 20px; }
    .title-cell a { color: #1e293b; text-decoration: none; font-weight: 500; }
    .title-cell a:hover { color: #7aa2f7; }
    
    /* 배지 (카테고리) */
    .badge { padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; color: white; margin-right: 8px; }
    .bg-news { background: #ff9e64; }
    .bg-drama { background: #bb9af7; }
    .bg-talk { background: #9ece6a; }
    
    /* 폼 입력 */
    .form-control { width: 100%; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; margin-top: 8px; box-sizing: border-box; font-family: inherit; font-size: 15px; }
    .form-control:focus { outline: none; border-color: #7aa2f7; box-shadow: 0 0 0 3px rgba(122,162,247,0.2); }
</style>
</head>
<body>
<div class="navbar">
    <a href="/index" class="navbar-brand">🪐 IssuePlanet</a>
    <div class="nav-links">
        <a href="/board/boardForm?category=news">📰 K-POP/뉴스</a>
        <a href="/board/boardForm?category=drama">🎬 드라마/영화</a>
        <a href="/board/boardForm?category=talk">💬 자유썰</a>
    </div>
    <div style="color: white; font-size: 14px;">
        <c:choose>
            <c:when test="${empty sessionScope.id}">
                <a href="/member/login" style="color: #7aa2f7; text-decoration: none; margin-right: 15px; font-weight: bold;">로그인</a>
                <a href="/member/regist" class="btn btn-primary" style="padding: 6px 12px;">회원가입</a>
            </c:when>
            <c:otherwise>
                <span style="color: #bb9af7; font-weight: bold; margin-right: 15px;">${sessionScope.id}님</span>
                <a href="/member/userInfo" style="color: #a9b1d6; text-decoration: none; margin-right: 15px;">내 정보</a>
                <a href="/member/logout" class="btn btn-danger" style="padding: 6px 12px;">로그아웃</a>
            </c:otherwise>
        </c:choose>
    </div>
</div>