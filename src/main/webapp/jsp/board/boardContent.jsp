<%@ page language="java" contentType="text/html; charset=UTF-8"   pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:import url="/header" />

<script>
	function deleteCheck(){
		result = confirm('진짜로 삭제하겠습니까?');
		if(result == true){
			location.href='boardDeleteProc?no=${board.no}'
		}
	}
</script>
<div align="center">
	<h1>글 내용</h1>
	<table border='1'>
		<tr>
			<th width="100">작성자</th>
			<td width="200">${board.id }</td>
			<th width="100">조회수</th>
			<td width="200">${board.hits }</td>
		</tr>
		<tr>
			<th>작성일</th>
			<td>${board.writeDate }</td>
			<th>다운로드</th>
			<c:choose>
				<c:when test="${empty board.fileName }">
					<td></td>
				</c:when>
				<c:otherwise>
					<td onclick="location.href='boardDownload?no=${board.no }'">
						${board.fileName }
					</td>
				</c:otherwise>
			</c:choose>
		</tr>
		<tr>
			<th>제목</th>
			<td colspan="3">${board.title }</td>
		</tr>
		<tr>
			<th>문서내용</th>
			<td colspan="3">${board.content }</td>
		</tr>
		<tr>
			<td colspan="4">
				<button type="button" onclick="location.href='boardForm'">목록</button>
				<button type="button" onclick="location.href='boardModify?no=${board.no }'">수정</button>
				<button type="button" onclick="deleteCheck()">삭제</button> 
			</td>
		</tr>
	</table>
</div>
<c:import url="/footer" />






