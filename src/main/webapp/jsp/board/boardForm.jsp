<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container">
    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 20px;">
        <h2 style="margin: 0; color: #1e293b;">
            <c:if test="${category == 'news'}">📰 K-POP/연예 뉴스</c:if>
            <c:if test="${category == 'drama'}">🎬 드라마/영화 리뷰</c:if>
            <c:if test="${category == 'talk'}">💬 자유 썰 게시판</c:if>
        </h2>
        <a href="/board/boardWrite" class="btn btn-primary">✍️ 글쓰기</a>
    </div>

    <table>
        <tr>
            <th width="10%">번호</th><th width="50%">제목</th><th width="15%">작성자</th><th width="15%">작성일</th><th width="10%">조회</th>
        </tr>
        <c:forEach var="board" items="${boardList}">
            <tr>
                <td style="color: #94a3b8;">${board.no}</td>
                <td class="title-cell">
                    <span class="badge bg-${board.category}">
                        ${board.category == 'news' ? '뉴스' : board.category == 'drama' ? '드라마' : '자유썰'}
                    </span>
                    <a href="/board/boardContent?no=${board.no}">${board.title}</a>
                    <c:if test="${board.likes > 0}">
                        <span style="color: #f7768e; font-size: 13px; font-weight: bold; margin-left: 5px;">[❤️${board.likes}]</span>
                    </c:if>
                </td>
                <td style="font-weight: 500;">${board.id}</td>
                <td style="color: #64748b; font-size: 13px;">${board.writeDate.substring(0, 10)}</td>
                <td style="color: #64748b;">${board.hit}</td>
            </tr>
        </c:forEach>
    </table>
</div>
</body>
</html>