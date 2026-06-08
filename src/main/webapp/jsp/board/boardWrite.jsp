<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container">
    <div style="margin-bottom: 30px; border-bottom: 2px solid #f1f5f9; padding-bottom: 15px;">
        <h2 style="margin: 0; color: #1e293b;">✍️ 새 게시글 작성</h2>
    </div>
    
    <form action="/board/boardWriteProc" method="post" enctype="multipart/form-data">
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
            <input type="text" name="title" class="form-control" required>
        </div>

        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569; display: block; margin-bottom: 8px;">이미지 첨부</label>
            <input type="file" name="file" class="form-control" accept="image/*">
        </div>
        
        <div style="margin-bottom: 30px;">
            <label style="font-weight: 600; color: #475569; display: block; margin-bottom: 8px;">내용</label>
            <textarea name="content" class="form-control" rows="10" required></textarea>
        </div>
        
        <div style="text-align: center;">
            <button type="submit" class="btn btn-primary" style="padding: 12px 40px;">게시글 등록</button>
        </div>
    </form>
</div>

<c:import url="../default/footer.jsp"/>