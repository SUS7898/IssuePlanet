<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:import url="../default/header.jsp"/>

<div class="container" style="max-width: 600px; margin: 50px auto;">
    <h2 style="font-weight: 800; color: #1e293b; margin-bottom: 30px; text-align: center;">회원정보 수정</h2>
    
    <c:if test="${not empty msg}">
        <script>alert("${msg}");</script>
    </c:if>

    <div style="background: #ffffff; padding: 40px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);">
        <form action="/member/updateProc" method="post">
            
            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">아이디</label>
                <input type="text" class="form-control" value="${sessionScope.id}" disabled style="background-color: #f1f5f9;">
                <small style="color: #94a3b8;">아이디는 변경할 수 없습니다.</small>
            </div>
            
            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">현재 비밀번호 <span style="color: #ef4444;">*</span></label>
                <input type="password" name="pw" class="form-control" placeholder="본인 확인을 위해 현재 비밀번호를 입력해주세요" required>
            </div>

            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">새 비밀번호 (변경 시에만 입력)</label>
                <input type="password" name="newPw" class="form-control" placeholder="변경할 새 비밀번호를 입력하세요">
            </div>

            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">새 비밀번호 확인</label>
                <input type="password" name="confirmNewPw" class="form-control" placeholder="새 비밀번호를 한번 더 입력하세요">
            </div>

            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">이름</label>
                <input type="text" name="userName" class="form-control" value="${sessionScope.userName}" required>
            </div>

            <div class="mb-4">
                <label style="font-weight: 600; color: #475569;">전화번호</label>
                <input type="text" name="mobile" class="form-control" value="${sessionScope.mobile}" placeholder="010-0000-0000">
            </div>

            <div class="mb-5">
                <label style="font-weight: 600; color: #475569;">주소</label>
                <input type="text" name="address" class="form-control" value="${sessionScope.address}" placeholder="주소를 입력하세요">
            </div>

            <button type="submit" class="btn btn-primary" style="width: 100%; padding: 14px; font-size: 16px; font-weight: bold; background-color: #1e3a8a; border: none; border-radius: 8px;">
                정보 수정 완료
            </button>
            
        </form>
    </div>
</div>

<c:import url="../default/footer.jsp"/>