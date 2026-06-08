<%@ page language="java" contentType="text/html; charset=UTF-8"  pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="/header" />
<div align="center">
	<h1>게시글 목록</h1>
		<c:choose>
			<c:when test="${empty boards }">
				<h1> 등록된 데이터가 존재하지 않습니다. </h1>
			</c:when>
			<c:otherwise>
				<table border=1>
					<tr>
						<th width="50">No.</th>
						<th width="250">제목</th>
						<th width="100">작성자</th>
						<th width="100">작성일</th>
						<th width="60">조회수</th>
					</tr>
					
					<c:forEach var="board" items="${ boards}">
						<tr>
							<td>${board.no }</td>
							<td onclick="location.href='boardContent?no=${board.no }'">
								${board.title }
							</td>
							<td>${board.id }</td>
							<td>${board.writeDate }</td>
							<td>${board.hits }</td>
						</tr>
					</c:forEach>
					<tr>
						<td colspan="4">
							${result }
						</td>
						<td><button type="button" onclick="location.href='boardWrite'">글쓰기</button></td>
					</tr>
				</table>
		</c:otherwise>
	</c:choose>
</div>
<c:import url="/footer" />










