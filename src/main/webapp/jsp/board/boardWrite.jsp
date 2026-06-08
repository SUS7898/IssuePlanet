<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<c:import url="../default/header.jsp"/>

<div class="container">
    <h2 style="margin-top: 0; margin-bottom: 25px; color: #1e293b; border-bottom: 2px solid #f1f5f9; padding-bottom: 15px;">✍️ 게시글 작성</h2>
    <form action="/board/boardWriteProc" method="post">
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569;">게시판 카테고리</label>
            <select name="category" class="form-control" style="width: 200px; display: block;">
                <option value="news">📰 K-POP/연예 뉴스</option>
                <option value="drama">🎬 드라마/영화 리뷰</option>
                <option value="talk">💬 자유 썰 게시판</option>
            </select>
        </div>
        
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569;">제목</label>
            <input type="text" name="title" class="form-control" placeholder="제목을 입력하세요." required>
        </div>
        
        <div style="margin-bottom: 30px;">
            <label style="font-weight: 600; color: #475569;">내용</label>
            <textarea name="content" class="form-control" rows="15" placeholder="내용을 입력하세요." required></textarea>
        </div>
        
        <div style="text-align: center; display: flex; gap: 10px; justify-content: center;">
            <button type="submit" class="btn btn-primary" style="padding: 12px 40px; font-size: 16px;">등록하기</button>
            <button type="button" onclick="history.back()" class="btn btn-secondary" style="padding: 12px 40px; font-size: 16px;">취소</button>
        </div>
    </form>
</div>
</body>
</html>