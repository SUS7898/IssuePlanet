package com.care.boot.board;

import java.util.HashMap;
import java.util.Map;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
@Controller
@RequestMapping("/board")
public class BoardController {

    @Autowired private BoardService service;
    @Autowired private HttpSession session;

    // 게시판 메인 리스트로 이동
    @GetMapping("/boardForm")
    public String boardForm(@RequestParam(value="category", defaultValue="news") String category,
                            @RequestParam(value="currentPage", defaultValue="1") String currentPage,
                            Model model) {
        service.boardForm(currentPage, category, model);
        model.addAttribute("category", category);
        return "board/boardForm";
    }

    // 글쓰기 폼 이동
    @GetMapping("/boardWrite")
    public String boardWrite() {
        return "board/boardWrite";
    }

    // 글 등록 처리
    @PostMapping("/boardWriteProc")
    public String boardWriteProc(BoardDTO board, @RequestParam("file") MultipartFile file) {
        String id = (String) session.getAttribute("id");
        if(id == null) return "redirect:/member/login";
        board.setId(id);
        service.boardWriteProc(board, file);
        return "redirect:/board/boardForm?category=" + board.getCategory();
    }

    // 본문 상세보기 (좋아요 유무 체크 바인딩)
    @GetMapping("/boardContent")
    public String boardContent(@RequestParam("no") int no, Model model, HttpSession session) {
        service.boardContent(no, model);
        
        String id = (String) session.getAttribute("id");
        if(id != null) {
            boolean isLiked = service.checkLike(no, id);
            model.addAttribute("isLiked", isLiked);
        }
        return "board/boardContent";
    }

    // 댓글 저장 라우터
    @PostMapping("/replyWrite")
    public String replyWrite(ReplyDTO reply, HttpSession session) {
        String id = (String) session.getAttribute("id");
        if(id != null) {
            reply.setId(id);
            service.insertReply(reply);
        }
        return "redirect:/board/boardContent?no=" + reply.getBoardNo();
    }

    // 좋아요 비동기 요청 API 토글
    @ResponseBody
    @PostMapping("/toggleLike")
    public Map<String, Object> toggleLike(@RequestParam("no") int no, HttpSession session) {
        Map<String, Object> response = new HashMap<>();
        String id = (String) session.getAttribute("id");
        
        if(id == null) {
            response.put("status", "login_required");
            return response;
        }
        
        int currentLikes = service.toggleLike(no, id);
        response.put("status", "success");
        response.put("likes", currentLikes);
        return response;
    }
    
    @GetMapping("/display")
    public ResponseEntity<Resource> display(@RequestParam("fileName") String fileName) {
        String path = "D:/temp/" + fileName;
        Resource resource = new FileSystemResource(path);
        
        if(!resource.exists()) return ResponseEntity.notFound().build();
        
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, "image/png") // 필요시 jpeg 등으로 확장자 구분 로직 추가
                .body(resource);
    }
}