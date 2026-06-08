<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="default/header.jsp"/>

<div class="container" style="text-align: center; padding: 60px 20px;">
    <h1 style="color: #1e293b; font-size: 36px; margin-bottom: 10px;">🪐 Welcome to IssuePlanet!</h1>
    <p style="color: #64748b; font-size: 18px; margin-bottom: 40px;">
        가장 빠르고 핫한 연예계 트렌드 & 이슈 커뮤니티에 오신 것을 환영합니다.
    </p>
    
    <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;">
        <a href="/board/boardForm?category=news" class="btn btn-primary" style="padding: 15px 30px; font-size: 18px; border-radius: 12px; box-shadow: 0 4px 6px rgba(122,162,247,0.3);">
            📰 실시간 연예 뉴스
        </a>
        <a href="/board/boardForm?category=talk" class="btn btn-secondary" style="padding: 15px 30px; font-size: 18px; border-radius: 12px;">
            💬 자유 썰 풀기
        </a>
    </div>
</div>

<c:import url="default/footer.jsp"/>