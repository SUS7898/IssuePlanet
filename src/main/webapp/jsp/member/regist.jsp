<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container" style="max-width: 600px;">
    <h2 style="text-align: center; color: #1e293b; margin-bottom: 30px;">회원가입</h2>
    
    <form action="/member/registProc" method="post">
        <div style="margin-bottom: 15px;">
            <label style="font-weight: 600; color: #475569;">아이디</label>
            <input type="text" name="id" class="form-control" required>
        </div>
        <div style="margin-bottom: 15px;">
            <label style="font-weight: 600; color: #475569;">비밀번호</label>
            <input type="password" name="pw" class="form-control" required>
        </div>
        <div style="margin-bottom: 15px;">
            <label style="font-weight: 600; color: #475569;">이름(닉네임)</label>
            <input type="text" name="username" class="form-control" required>
        </div>
        <div style="margin-bottom: 15px;">
            <label style="font-weight: 600; color: #475569;">전화번호</label>
            <input type="text" name="mobile" class="form-control" placeholder="010-0000-0000">
        </div>
        
        <div style="margin-bottom: 15px;">
            <label style="font-weight: 600; color: #475569;">주소</label>
            <div style="display: flex; gap: 10px; margin-bottom: 8px;">
                <input type="text" name="postcode" class="form-control" placeholder="우편번호" style="width: 150px;">
                <button type="button" class="btn btn-secondary">우편번호 찾기</button>
            </div>
            <input type="text" name="address" class="form-control" placeholder="기본 주소" style="margin-bottom: 8px;">
            <input type="text" name="detailaddress" class="form-control" placeholder="상세 주소">
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <button type="submit" class="btn btn-primary" style="padding: 12px 40px; font-size: 16px;">가입하기</button>
            <button type="button" onclick="history.back()" class="btn btn-secondary" style="padding: 12px 40px; font-size: 16px; margin-left: 10px;">취소</button>
        </div>
    </form>
</div>

<c:import url="../default/footer.jsp"/>