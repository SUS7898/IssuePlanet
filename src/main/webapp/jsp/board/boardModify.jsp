<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container">
    <h2 style="margin-top: 0; margin-bottom: 25px; color: #1e293b; border-bottom: 2px solid #f1f5f9; padding-bottom: 15px;">✏️ 게시글 수정</h2>
    <form action="/board/boardModifyProc" method="post">
        <input type="hidden" name="no" value="${board.no}">
        <input type="hidden" name="category" value="${board.category}">
        
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569;">제목</label>
            <input type="text" name="title" class="form-control" value="${board.title}" required>
        </div>
        
        <div style="margin-bottom: 30px;">
            <label style="font-weight: 600; color: #475569;">내용</label>
            <textarea name="content" class="form-control" rows="15" required>${board.content}</textarea>
        </div>
        
        <div style="text-align: center; display: flex; gap: 10px; justify-content: center;">
            <button type="submit" class="btn btn-primary" style="padding: 12px 40px; font-size: 16px;">수정완료</button>
            <button type="button" onclick="history.back()" class="btn btn-secondary" style="padding: 12px 40px; font-size: 16px;">취소</button>
        </div>
    </form>
</div>

<c:import url="../default/footer.jsp"/>