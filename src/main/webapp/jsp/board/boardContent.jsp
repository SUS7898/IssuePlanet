<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container">
    <div style="border-bottom: 2px solid #f1f5f9; padding-bottom: 20px; margin-bottom: 30px;">
        <span class="badge bg-${board.category}" style="font-size: 14px; padding: 6px 12px;">
            ${board.category == 'news' ? '뉴스' : board.category == 'drama' ? '드라마' : '자유썰'}
        </span>
        <h1 style="margin: 15px 0; color: #1e293b;">${board.title}</h1>
        <div style="color: #64748b; font-size: 14px;">
            <span style="font-weight: 600; color: #334155; margin-right: 15px;">👤 ${board.id}</span>
            <span style="margin-right: 15px;">🕒 ${board.writeDate}</span>
            <span>👁️ 조회 ${board.hit}</span>
        </div>
    </div>
    
    <div style="min-height: 250px; font-size: 16px; line-height: 1.8; color: #334155;">
        ${board.content}
    </div>

    <div style="text-align: center; margin: 50px 0;">
        <button onclick="toggleLike(${board.no})" id="likeBtn" 
                style="padding: 12px 30px; font-size: 18px; font-weight: bold; cursor: pointer; border-radius: 30px; transition: 0.3s;
                background-color: ${isLiked ? '#f7768e' : '#fff'}; 
                color: ${isLiked ? '#fff' : '#f7768e'}; 
                border: 2px solid #f7768e;">
            ${isLiked ? '❤️ 좋아요 취소' : '🤍 좋아요'} <span id="likeCount">${board.likes}</span>
        </button>
    </div>

    <div style="background-color: #f8fafc; padding: 30px; border-radius: 12px; margin-top: 30px;">
        <h3 style="margin-top: 0; color: #1e293b;">💬 댓글 <span style="color: #7aa2f7;">${replies.size()}</span></h3>
        
        <div style="margin-bottom: 30px;">
            <c:forEach var="reply" items="${replies}">
                <div style="background: #fff; padding: 15px 20px; border-radius: 8px; margin-bottom: 10px; border: 1px solid #e2e8f0;">
                    <div style="margin-bottom: 8px;">
                        <b style="color: #334155;">${reply.id}</b> 
                        <span style="color: #94a3b8; font-size: 12px; margin-left: 10px;">${reply.writeDate}</span>
                    </div>
                    <div style="color: #475569;">${reply.content}</div>
                </div>
            </c:forEach>
        </div>
        
        <c:choose>
            <c:when test="${not empty sessionScope.id}">
                <form action="/board/replyWrite" method="post" style="display: flex; gap: 10px;">
                    <input type="hidden" name="boardNo" value="${board.no}">
                    <textarea name="content" class="form-control" style="flex: 1; resize: none;" rows="2" placeholder="클린한 댓글 문화를 만들어가요!" required></textarea>
                    <button type="submit" class="btn btn-primary" style="white-space: nowrap; margin-top: 8px;">등록</button>
                </form>
            </c:when>
            <c:otherwise>
                <div style="text-align: center; padding: 20px; background: #fff; border-radius: 8px; color: #64748b;">
                    댓글을 작성하려면 <a href="/member/login" style="color: #7aa2f7; font-weight: bold;">로그인</a>이 필요합니다.
                </div>
            </c:otherwise>
        </c:choose>
    </div>
    
    <div style="text-align: right; margin-top: 30px;">
        <a href="/board/boardForm?category=${board.category}" class="btn btn-secondary">목록으로</a>
    </div>
</div>

<script>
function toggleLike(boardNo) {
    fetch('/board/toggleLike', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'no=' + boardNo
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'login_required') {
            alert("로그인이 필요합니다!");
            location.href = '/member/login';
        } else if (data.status === 'success') {
            document.getElementById('likeCount').innerText = data.likes;
            let btn = document.getElementById('likeBtn');
            if(btn.style.backgroundColor === 'rgb(247, 118, 142)' || btn.style.backgroundColor === '#f7768e') {
                btn.style.backgroundColor = '#fff';
                btn.style.color = '#f7768e';
                btn.innerHTML = '🤍 좋아요 <span id="likeCount">' + data.likes + '</span>';
            } else {
                btn.style.backgroundColor = '#f7768e';
                btn.style.color = '#fff';
                btn.innerHTML = '❤️ 좋아요 취소 <span id="likeCount">' + data.likes + '</span>';
            }
        }
    });
}
</script>
</body>
</html>