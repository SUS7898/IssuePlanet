package com.care.boot.member;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/member")
public class MemberController {
    
    @Autowired private MemberService service;
    @Autowired private HttpSession session;
    
    // 회원가입 페이지 이동
    @RequestMapping("/regist")
    public String regist() {
        return "member/regist";
    }
    
    // 회원가입 처리 로직
    @PostMapping("/registProc")
    public String registProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String msg = service.registProc(member);
        
        if(msg.equals("회원 등록 완료")) {
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index"; 
        }
        
        model.addAttribute("msg", msg);
        return "member/regist";
    }
    
    // 로그인 페이지 이동
    @RequestMapping("/login")
    public String login() {
        return "member/login";
    }
    
    // 로그인 처리 로직
    @PostMapping("/loginProc")
    public String loginProc(String id, String pw, Model model, RedirectAttributes ra) {
        String msg = service.loginProc(id, pw);
        if(msg.equals("로그인 성공")) {
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        
        // 실패 시 안전하게 리다이렉트하여 URL 왜곡 방지
        ra.addFlashAttribute("msg", msg);
        return "redirect:/member/login";
    }
    
    // 로그아웃 처리 로직
    @RequestMapping("/logout")
    public String logout(RedirectAttributes ra) {
        session.invalidate();
        ra.addFlashAttribute("msg", "로그 아웃 완료");
        return "redirect:/";
    }

    // 내 정보 보기 조회 (대소문자 파일명 매칭 보정)
    @RequestMapping("/userInfo")
    public String userInfo(@RequestParam(value="id", required=false) String id, Model model) {
        if (id == null || id.isEmpty()) {
            id = (String) session.getAttribute("id");
        }
        
        String msg = service.userInfo(id, model);
        if (msg.equals("회원 검색 완료")) {
            return "member/userInfo"; 
        }
        
        model.addAttribute("msg", msg);
        return "redirect:/index";
    }

    // 회원 전체 목록 조회 (관리자용)
    @RequestMapping("/memberInfo")
    public String memberInfo(@RequestParam(value="select", required=false) String select,
                             @RequestParam(value="search", required=false) String search,
                             @RequestParam(value="currentPage", defaultValue="1") String cp,
                             Model model) {
        service.memberInfo(select, search, cp, model);
        return "member/memberInfo";
    }

    // 회원 정보 수정 폼 이동
    @GetMapping("/update")
    public String update() {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) {
            return "redirect:/member/login";
        }
        return "member/update";
    }

 // 회원 정보 수정 처리 로직
 // 회원 정보 수정 처리 로직 (새 비밀번호 파라미터 수집 추가)
    @PostMapping("/updateProc")
    public String updateProc(MemberDTO member, 
                             @RequestParam(value="newPw", required=false) String newPw,
                             @RequestParam(value="confirmNewPw", required=false) String confirmNewPw,
                             RedirectAttributes ra) {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) {
            return "redirect:/member/login";
        }
        
        member.setId(sessionId);

        // 서비스 레이어로 새 비밀번호 데이터들까지 함께 전달합니다.
        String msg = service.updateProc(member, newPw, confirmNewPw);
        
        if (msg.equals("회원 수정 완료")) {
            session.setAttribute("userName", member.getUserName());
            session.setAttribute("address", member.getAddress());
            session.setAttribute("mobile", member.getMobile());
            
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        
        ra.addFlashAttribute("msg", msg);
        return "redirect:/member/update";
    }

    // 회원 탈퇴 폼 이동
    @GetMapping("/delete")
    public String delete() {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) {
            return "redirect:/member/login";
        }
        return "member/delete";
    }

    // 회원 탈퇴 처리 로직
    @PostMapping("/deleteProc")
    public String deleteProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) return "redirect:/member/login";
        
        member.setId(sessionId);
        String msg = service.deleteProc(member);
        
        if (msg.equals("회원 삭제 완료")) {
            session.invalidate();
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        
        model.addAttribute("msg", msg);
        return "member/delete";
    }
}