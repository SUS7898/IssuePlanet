<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<div class="container" style="max-width: 600px;">
    <h2 style="color: #1e293b; border-bottom: 2px solid #f1f5f9; padding-bottom: 15px; margin-bottom: 30px;">나의 정보</h2>
    
    <table style="width: 100%; text-align: left;">
        <tr>
            <th style="width: 30%; background: #f8fafc; padding: 15px;">아이디</th>
            <td style="padding: 15px; border-bottom: 1px solid #f1f5f9;">${member.id}</td>
        </tr>
        <tr>
            <th style="background: #f8fafc; padding: 15px;">이름(닉네임)</th>
            <td style="padding: 15px; border-bottom: 1px solid #f1f5f9;">${member.username}</td>
        </tr>
        <tr>
            <th style="background: #f8fafc; padding: 15px;">전화번호</th>
            <td style="padding: 15px; border-bottom: 1px solid #f1f5f9;">${member.mobile}</td>
        </tr>
        <tr>
            <th style="background: #f8fafc; padding: 15px;">주소</th>
            <td style="padding: 15px; border-bottom: 1px solid #f1f5f9;">
                [${member.postcode}] ${member.address} ${member.detailaddress}
            </td>
        </tr>
    </table>
    
    <div style="text-align: center; margin-top: 30px;">
        <a href="/member/update" class="btn btn-primary" style="padding: 10px 30px;">정보 수정</a>
        <a href="/member/delete" class="btn btn-danger" style="padding: 10px 30px; margin-left: 10px;">회원 탈퇴</a>
    </div>
</div>

<c:import url="../default/footer.jsp"/>