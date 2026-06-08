<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container">
    <div style="margin-bottom: 30px; border-bottom: 2px solid #f1f5f9; padding-bottom: 15px;">
        <h2 style="margin: 0; color: #1e293b;">✍️ 새 게시글 작성</h2>
        <p style="color: #64748b; margin-top: 5px;">당신의 이야기를 IssuePlanet에 공유해 주세요.</p>
    </div>
    
    <form action="/board/boardWriteProc" method="post">
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569; display: block; margin-bottom: 8px;">게시판 선택</label>
            <select name="category" class="form-control" style="width: 250px;">
                <option value="news">📰 K-POP/연예 뉴스</option>
                <option value="drama">🎬 드라마/영화 리뷰</option>
                <option value="talk">💬 자유 썰 게시판</option>
            </select>
        </div>
        
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569; display: block; margin-bottom: 8px;">제목</label>
            <input type="text" name="title" class="form-control" placeholder="제목을 입력하세요." required>
        </div>
        
        <div style="margin-bottom: 30px;">
            <label style="font-weight: 600; color: #475569; display: block; margin-bottom: 8px;">내용</label>
            <textarea name="content" class="form-control" rows="15" placeholder="이슈에 대한 여러분의 생각을 자유롭게 적어주세요." required></textarea>
        </div>
        
        <div style="text-align: center; display: flex; gap: 15px; justify-content: center;">
            <button type="submit" class="btn btn-primary" style="padding: 14px 50px; font-size: 16px;">게시글 등록</button>
            <button type="button" onclick="history.back()" class="btn btn-secondary" style="padding: 14px 50px; font-size: 16px;">작성 취소</button>
        </div>
    </form>
</div>

<c:import url="../default/footer.jsp"/>